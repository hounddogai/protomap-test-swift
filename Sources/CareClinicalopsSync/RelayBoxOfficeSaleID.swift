import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayBoxOfficeSaleID keeps of each GetBoxOfficeSale response.
struct RelayBoxOfficeSaleIDRecord {
    var boxOfficeSaleID: String
    var message: String
    var status: String
    var correlationID: String
}

/// Where RelayBoxOfficeSaleID hands each record.
protocol RelayBoxOfficeSaleIDSink {
    func deliver(_ rec: RelayBoxOfficeSaleIDRecord) async throws
}

/// Passes records to acme.patients.v1.PatientWorkflowService.
struct RelayBoxOfficeSaleIDPatientWorkflow: RelayBoxOfficeSaleIDSink {
    let client: Acme_Patients_V1_PatientWorkflowService.Client<MeshTransport>

    func deliver(_ rec: RelayBoxOfficeSaleIDRecord) async throws {
        _ = try await client.inspectPatientWorkflow(.with {
            $0.patientID = rec.status
        })
    }
}

/// Writes records to acme.collections.v1.CollectionCaseService.
struct RelayBoxOfficeSaleIDCollectionCase: RelayBoxOfficeSaleIDSink {
    let client: Acme_Collections_V1_CollectionCaseService.Client<MeshTransport>

    func deliver(_ rec: RelayBoxOfficeSaleIDRecord) async throws {
        let request = Acme_Collections_V1_UpdateCollectionCaseRequest.with {
            $0.collectionCase.collectionCaseID = rec.boxOfficeSaleID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.updateCollectionCase(request)
        }
    }
}

/// Writes records to acme.prescriptions.v1.RefillCalculationService.
struct RelayBoxOfficeSaleIDRefillCalculation: RelayBoxOfficeSaleIDSink {
    let client: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>

    func deliver(_ rec: RelayBoxOfficeSaleIDRecord) async throws {
        _ = try await client.estimateRefill(.with {
            $0.refillID = rec.status
            $0.refill.subject = rec.message
        })
    }
}

/// Reads acme.boxoffice.v1.BoxOfficeSaleService/GetBoxOfficeSale and hands what it keeps to the sink of its kind.
enum RelayBoxOfficeSaleID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Boxoffice_V1_BoxOfficeSaleService.Client(wrapping: mesh)
        let response = try await reader.getBoxOfficeSale(.with { $0.boxOfficeSaleID = "live-relay-box-office-sale-id" })
        let record = RelayBoxOfficeSaleIDRecord(
            boxOfficeSaleID: Kit.Text.normalize(response.boxOfficeSale.boxOfficeSaleID),
            message: Kit.Text.normalize(response.result.message),
            status: response.result.status,
            correlationID: response.result.correlationID
        )
        let sinks: [String: any RelayBoxOfficeSaleIDSink] = [
            "patient-workflow": RelayBoxOfficeSaleIDPatientWorkflow(client: Acme_Patients_V1_PatientWorkflowService.Client(wrapping: mesh)),
            "collection-case": RelayBoxOfficeSaleIDCollectionCase(client: Acme_Collections_V1_CollectionCaseService.Client(wrapping: mesh)),
            "refill-calculation": RelayBoxOfficeSaleIDRefillCalculation(client: Acme_Prescriptions_V1_RefillCalculationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "patient-workflow" {
                continue
            }
            try await sink.deliver(record)
        }
    }
}
