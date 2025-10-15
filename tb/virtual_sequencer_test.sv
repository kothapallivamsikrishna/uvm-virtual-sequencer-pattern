`include "uvm_macros.svh"
import uvm_pkg::*;

///////////////////////////// ADDER AGENT COMPONENTS /////////////////////////////
class add_transaction extends uvm_sequence_item;
  `uvm_object_utils(add_transaction)
  rand logic [3:0] add_in1,add_in2;
  logic [4:0] add_out;
  function new(string name = "add_transaction"); super.new(name); endfunction
endclass

class add_sequence extends uvm_sequence#(add_transaction);
  `uvm_object_utils(add_sequence)
  function new(string name = "add_sequence"); super.new(name); endfunction
  virtual task body();
    repeat(5) `uvm_do_with(req, {add_in1 inside {[1:5]}; add_in2 inside {[1:5]};})
  endtask
endclass

class add_driver extends uvm_driver #(add_transaction);
  `uvm_component_utils(add_driver)
  virtual add_if aif;
  function new(string n="add_driver", uvm_component p=null); super.new(n,p); endfunction
  virtual function void build_phase(uvm_phase phase);
    if(!uvm_config_db#(virtual add_if)::get(this,"","aif",aif)) `uvm_fatal("DRV","Cannot get add_if");
  endfunction
  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info("ADD_DRV", $sformatf("Driving: add_in1=%0d, add_in2=%0d", req.add_in1, req.add_in2), UVM_MEDIUM);
      aif.add_in1 <= req.add_in1;
      aif.add_in2 <= req.add_in2;
      @(posedge aif.clk);
      seq_item_port.item_done();
    end
  endtask
endclass

class add_agent extends uvm_agent;
  `uvm_component_utils(add_agent)
  add_driver d;
  uvm_sequencer #(add_transaction) a_seqr;
  function new(string n="add_agent", uvm_component p=null); super.new(n,p); endfunction
  virtual function void build_phase(uvm_phase phase);
    d = add_driver::type_id::create("d",this);
    a_seqr = uvm_sequencer #(add_transaction)::type_id::create("a_seqr", this);
  endfunction
  virtual function void connect_phase(uvm_phase phase);
    d.seq_item_port.connect(a_seqr.seq_item_export);
  endfunction
endclass

///////////////////////////// MULTIPLIER AGENT COMPONENTS /////////////////////////////
class mul_transaction extends uvm_sequence_item;
  `uvm_object_utils(mul_transaction)
  rand logic [3:0] mul_in1,mul_in2;
  logic [7:0] mul_out;
  function new(string name = "mul_transaction"); super.new(name); endfunction
endclass

class mul_sequence extends uvm_sequence#(mul_transaction);
  `uvm_object_utils(mul_sequence)
  function new(string name = "mul_sequence"); super.new(name); endfunction
  virtual task body();
    repeat(5) `uvm_do_with(req, {mul_in1 inside {[1:5]}; mul_in2 inside {[1:5]};})
  endtask
endclass

class mul_driver extends uvm_driver #(mul_transaction);
  `uvm_component_utils(mul_driver)
  virtual mul_if mif;
  function new(string n="mul_driver", uvm_component p=null); super.new(n,p); endfunction
  virtual function void build_phase(uvm_phase phase);
    if(!uvm_config_db#(virtual mul_if)::get(this,"","mif",mif)) `uvm_fatal("DRV","Cannot get mul_if");
  endfunction
  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info("MUL_DRV", $sformatf("Driving: mul_in1=%0d, mul_in2=%0d", req.mul_in1, req.mul_in2), UVM_MEDIUM);
      mif.mul_in1 <= req.mul_in1;
      mif.mul_in2 <= req.mul_in2;
      @(posedge mif.clk);
      seq_item_port.item_done();
    end
  endtask
endclass

class mul_agent extends uvm_agent;
  `uvm_component_utils(mul_agent)
  mul_driver d;
  uvm_sequencer #(mul_transaction) m_seqr;
  function new(string n="mul_agent", uvm_component p=null); super.new(n,p); endfunction
  virtual function void build_phase(uvm_phase phase);
    d = mul_driver::type_id::create("d",this);
    m_seqr = uvm_sequencer #(mul_transaction)::type_id::create("m_seqr", this);
  endfunction
  virtual function void connect_phase(uvm_phase phase);
    d.seq_item_port.connect(m_seqr.seq_item_export);
  endfunction
endclass

///////////////////////////// VIRTUAL SEQUENCER & SEQUENCES /////////////////////////////
class v_sequencer extends uvm_sequencer;
  `uvm_component_utils(v_sequencer)
  uvm_sequencer #(add_transaction) add_seqr_h; // Handle for adder sequencer
  uvm_sequencer #(mul_transaction) mul_seqr_h; // Handle for multiplier sequencer
  function new(string n="v_sequencer", uvm_component p=null); super.new(n,p); endfunction
endclass

class v_sequence_base extends uvm_sequence;
  `uvm_object_utils(v_sequence_base)
  v_sequencer v_seqr;
  function new(string n="v_sequence_base"); super.new(n); endfunction
  virtual task pre_body();
    if (!$cast(v_seqr, m_sequencer))
      `uvm_fatal(get_full_name(), "Virtual sequencer pointer cast failed")
  endtask
endclass

// A virtual sequence that runs both adder and multiplier sequences in parallel
class parallel_add_mul_vseq extends v_sequence_base;
  `uvm_object_utils(parallel_add_mul_vseq)
  function new(string n="parallel_add_mul_vseq"); super.new(n); endfunction
  virtual task body();
    add_sequence add_seq = add_sequence::type_id::create("add_seq");
    mul_sequence mul_seq = mul_sequence::type_id::create("mul_seq");
    fork
      add_seq.start(v_seqr.add_seqr_h);
      mul_seq.start(v_seqr.mul_seqr_h);
    join
  endtask
endclass

///////////////////////////// ENVIRONMENT /////////////////////////////
class env extends uvm_env;
  `uvm_component_utils(env)
  add_agent add_agent_inst;
  mul_agent mul_agent_inst;
  v_sequencer v_seqr_inst;
  function new(string n="env", uvm_component p=null); super.new(n,p); endfunction

  virtual function void build_phase(uvm_phase phase);
    add_agent_inst = add_agent::type_id::create("add_agent_inst",this);
    mul_agent_inst = mul_agent::type_id::create("mul_agent_inst", this);
    v_seqr_inst = v_sequencer::type_id::create("v_seqr_inst", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    // Connect the virtual sequencer handles to the actual agent sequencers
    v_seqr_inst.add_seqr_h = add_agent_inst.a_seqr;
    v_seqr_inst.mul_seqr_h = mul_agent_inst.m_seqr;
  endfunction
endclass

///////////////////////////// TEST & TOP MODULE /////////////////////////////
class test extends uvm_test;
  `uvm_component_utils(test)
  env env_inst;
  function new(string n="test", uvm_component p=null); super.new(n,p); endfunction

  virtual function void build_phase(uvm_phase phase);
    env_inst = env::type_id::create("env_inst",this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    parallel_add_mul_vseq v_seq = parallel_add_mul_vseq::type_id::create("v_seq");
    phase.raise_objection(this);
    v_seq.start(env_inst.v_seqr_inst);
    #200;
    phase.drop_objection(this);
  endtask
endclass

module tb;
    add_if aif();
    mul_if mif();

    top dut (.aa(aif.add_in1), .ab(aif.add_in2), .ma(mif.mul_in1), .mb(mif.mul_in2),
             .clk(aif.clk), .rst(aif.rst), .aout(aif.add_out), .mout(mif.mul_out));

    initial begin
      aif.clk <= 0;
      aif.rst <= 1; // Assert reset
      forever #10 aif.clk = ~aif.clk;
    end
    assign mif.clk = aif.clk;
    assign mif.rst = aif.rst;

    initial begin
      uvm_config_db#(virtual add_if)::set(null, "*", "aif", aif);
      uvm_config_db#(virtual mul_if)::set(null, "*", "mif", mif);
      
      // De-assert reset after some time
      #50 aif.rst = 0;

      run_test("test");
    end
endmodule
