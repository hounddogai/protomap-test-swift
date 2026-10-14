import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateGetAppointmentsID keeps of each BatchGetAppointments response.
struct PropagateGetAppointmentsIDRecord {
    var correlationID: String
    var status: String
    var nextPageToken: String
}

/// Where PropagateGetAppointmentsID hands each record.
protocol PropagateGetAppointmentsIDWriter {
    func apply(_ rec: PropagateGetAppointmentsIDRecord) async throws
}

/// Writes records to acme.payroll.v1.PayRunQueryService.
struct PropagateGetAppointmentsIDPayRunQuery: PropagateGetAppointmentsIDWriter {
    let client: Acme_Payroll_V1_PayRunQueryService.Client<MeshTransport>

    func apply(_ rec: PropagateGetAppointmentsIDRecord) async throws {
        let request = Acme_Payroll_V1_PeekPayRunRequest.with {
            $0.payRunID = rec.nextPageToken
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.peekPayRun(request)
        }
    }
}

/// Passes records to acme.admissions.v1.AdmissionCalculationService.
struct PropagateGetAppointmentsIDAdmissionCalculation: PropagateGetAppointmentsIDWriter {
    let client: Acme_Admissions_V1_AdmissionCalculationService.Client<MeshTransport>

    func apply(_ rec: PropagateGetAppointmentsIDRecord) async throws {
        let request = Acme_Admissions_V1_ExplainAdmissionCalculationRequest.with {
            $0.admissionID = rec.status
            $0.details.locale = rec.nextPageToken
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.explainAdmissionCalculation(request)
        }
    }
}

/// Writes records to acme.accounting.v1.ChartOfAccountsService.
struct PropagateGetAppointmentsIDChartOfAccounts: PropagateGetAppointmentsIDWriter {
    let client: Acme_Accounting_V1_ChartOfAccountsService.Client<MeshTransport>

    func apply(_ rec: PropagateGetAppointmentsIDRecord) async throws {
        let request = Acme_Accounting_V1_ListChartOfAccountsesRequest.with {
            $0.page.pageToken = rec.correlationID
            $0.filter.ownerID = rec.nextPageToken
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.listChartOfAccountses(request)
        }
    }
}

/// Reads acme.appointments.v1.AppointmentService/BatchGetAppointments and hands what it keeps to the sink of its kind.
enum PropagateGetAppointmentsID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Appointments_V1_AppointmentService.Client(wrapping: mesh)
        let response = try await upstream.batchGetAppointments(.init())
        let rec = PropagateGetAppointmentsIDRecord(
            correlationID: response.result.correlationID,
            status: Kit.Text.normalize(response.result.status),
            nextPageToken: response.pageInfo.nextPageToken
        )
        let sinks: [String: any PropagateGetAppointmentsIDWriter] = [
            "pay-run-query": PropagateGetAppointmentsIDPayRunQuery(client: Acme_Payroll_V1_PayRunQueryService.Client(wrapping: mesh)),
            "admission-calculation": PropagateGetAppointmentsIDAdmissionCalculation(client: Acme_Admissions_V1_AdmissionCalculationService.Client(wrapping: mesh)),
            "chart-of-accounts": PropagateGetAppointmentsIDChartOfAccounts(client: Acme_Accounting_V1_ChartOfAccountsService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["PROPAGATE_GET_APPOINTMENTS_ID_TARGET"] ?? ""] else {
            return
        }
        try await sink.apply(rec)
    }
}
