<%-- 
    Document   : getEmiDetails
    Created on : 5 Mar, 2018, 1:28:03 AM
    Author     : Suhas
--%>

<%@page import="java.sql.Connection"%>
<%@page import="java.sql.Statement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.Date"%>
<%@page import="controllers.Database"%>
<%@page import="java.sql.SQLException"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%  Connection con;
    Statement st;
    ResultSet rs1, rs2, rs3, rs4, rs5, rs7;

    Date approvedDate = null;
    java.util.Date utilDate = new java.util.Date();
    Date today = new Date(utilDate.getTime());

    System.out.println(today);
    int emiAmount = 0;
    int interestAmount = 0;
    int totalAmount = 0;
    int fine = 0;
    int totalemipaid = 0;
    int emiRemaining = 0, totalEMI = 0;

    String emailId = request.getParameter("emailid").toString();
    System.out.println("'" + emailId + "'");

    try {
        con = Database.connect();
        st = con.createStatement();

        rs1 = st.executeQuery("select * from loan_application where c_emailid='" + emailId + "'");
        boolean brs1 = rs1.next();
        rs7 = st.executeQuery("select status from loan_application where c_emailid='" + emailId + "' order by status limit 1");
        boolean brs7 = false;
        if (rs7.next()) {
            int status = rs7.getInt(1);
            if (status == 3) {
                brs7 = true;
            }
        }

        rs2 = st.executeQuery("select * from loan_application where c_emailid='" + emailId + "' && status=0");
        boolean brs2 = rs2.next();
        rs3 = st.executeQuery("select * from loan_application where id=(select id from loan_application where c_emailid='" + emailId + "' order by status asc limit 1) && status=2");
        boolean brs3 = rs3.next();

        if ((!brs1 || brs7)) {
%>

<center><h1><small><%= emailId%> not apply for any loan.</small></h1><br></center>

<%  } else if (brs2) {
%>

<center><h1><small><%= emailId%> loan application is being processed.</small></h1><br></center>

<%
} else if (brs3) {
%>

<center>
    <h1><small><%= emailId%> loan application is rejected.</small></h1><br>
</center>

<%  } else {
    rs4 = st.executeQuery("select * from emi_details where c_emailid='" + emailId + "'");
    rs4.next();
    emiAmount = rs4.getInt(2);
    interestAmount = rs4.getInt(3);
    totalAmount = rs4.getInt(4);

%>
<h3>EMI Details</h3>
<table class="table table-bordered table-hover table-responsive table-striped">
    <tr>
        <th>EMI Amount (in &#8377; )</th>
        <th>Interest Amount (in &#8377; )</th>
        <th>Total Amount (in &#8377; )</th>
    </tr>
    <tr>
        <td><%= emiAmount%></td>
        <td><%= interestAmount%></td>
        <td><%= totalAmount%></td>
    </tr>
</table>

<%  rs5 = st.executeQuery("select approved_date from customer_loan_details where c_emailid='" + emailId + "' && status=1");
    rs5.next();
    approvedDate = rs5.getDate(1);
    rs5.close();
    rs5 = st.executeQuery("select max(total_emi_paid) from paid_emi where c_emailid='" + emailId + "'");
    totalemipaid = 0;
    if (rs5.next()) {
        totalemipaid = rs5.getInt(1);
    }

    approvedDate.setMonth(approvedDate.getMonth() + totalemipaid + 1);

    rs5 = st.executeQuery("select tenure from loan_details where id=(select loan_id from customer_loan_details where c_emailid='" + emailId + "')");
    rs5.next();
    totalEMI = (rs5.getInt(1)) * 12;
    emiRemaining = totalEMI - totalemipaid;
%>
<br>
<p><b>Total EMI Remaining: <%= emiRemaining%></b></p><br>
<p><b>Your next due date is on: <%= approvedDate%></b></p><br>

<%
    if (approvedDate.compareTo(today) < 0) {
        fine = 150;
    }
    if (emiRemaining > 0) {
%>

<h3>Pay EMI</h3>
<form class="form-horizontal" method="POST" action="../PayEMI">
    <input type="hidden" name="admin" value="admin">
    <input type="hidden" name="emailID" value="<%= emailId%>">
    <div class="form-group">
        <label for="totalemipaid" class="col-sm-3 control-label">Total EMI Paid</label>
        <div class="col-sm-9">
            <input type="text" class="form-control" id="totalemipaid" name="totalemipaid" required value="<%= totalemipaid%>" readonly="true">
        </div>
    </div>
    <div class="form-group">
        <label for="emidate" class="col-sm-3 control-label">EMI Date</label>
        <div class="col-sm-9">
            <input type="date" class="form-control" id="emidate" name="emidate" required value="<%= approvedDate%>" readonly="true">
        </div>
    </div>
    <div class="form-group">
        <label for="paymentdate" class="col-sm-3 control-label">Payment Date</label>
        <div class="col-sm-9">
            <input type="date" class="form-control" id="paymentdate" name="paymentdate" required value="<%= today%>" readonly="true">
        </div>
    </div>
    <div class="form-group">
        <label for="emiamount" class="col-sm-3 control-label">Payment Amount</label>
        <div class="col-sm-9">
            <input type="number" class="form-control" id="emiamount" name="emiamount" required value="<%= totalAmount%>" readonly="true">
        </div>
    </div>
    <div class="form-group">
        <label for="latefine" class="col-sm-3 control-label">Late Fine</label>
        <div class="col-sm-9">
            <input type="number" class="form-control" id="latefine" name="latefine" required value="<%= fine%>" readonly="true">
        </div>
    </div>
    <div class="form-group">
        <label for="totalpayment" class="col-sm-3 control-label">Total Payment Fine</label>
        <div class="col-sm-9">
            <input type="number" class="form-control" id="totalpayment" name="totalpayment" required value="<%= totalAmount + fine%>" readonly="true">
        </div>
    </div>
    <div class="form-group">
        <div class="col-sm-offset-3 col-sm-6">
            <button type="submit" class="btn btn-default btn-block">Apply</button>
        </div>
    </div>
</form>

<%  } else {
        st.executeUpdate("update loan_application set status = 3 where c_emailid='" + emailId + "' && status = 1");
    }
%>
<br>
<h3>Paid EMI Details</h3>
<table class="table table-bordered table-hover table-responsive table-striped">
    <tr>
        <th>No. of payment</th>
        <th>EMI Date</th>
        <th>Receipt Date</th>
        <th>EMI Amount</th>
        <th>Late Fine</th>
        <th>Total EMI Amount</th>
    </tr>
    <%
        rs5 = st.executeQuery("select * from paid_emi where c_emailid='" + emailId + "'");
        while (rs5.next()) {
    %>
    <tr>
        <td><%= rs5.getInt(7)%></td>
        <td><%= rs5.getDate(4)%></td>
        <td><%= rs5.getDate(5)%></td>
        <td><%= rs5.getFloat(3)%></td>
        <td><%= rs5.getFloat(6)%></td>
        <td><%= rs5.getFloat(3) + rs5.getFloat(6)%></td>
    </tr>
    <%  }
    %>
</table>

<%  }
    } catch (SQLException e) {
        System.out.println(e.toString());
    }
%>
