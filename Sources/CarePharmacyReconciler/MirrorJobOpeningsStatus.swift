import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorJobOpeningsStatus keeps of each ListJobOpenings response.
struct MirrorJobOpeningsStatusRecord {
    var status: String
    var correlationID: String
}

/// Where MirrorJobOpeningsStatus hands each record.
protocol MirrorJobOpeningsStatusDestination {
    func forward(_ rec: MirrorJobOpeningsStatusRecord) async throws
}

/// Writes records to acme.patientapp.v1.PatientHomeService.
struct MirrorJobOpeningsStatusPatientHome: MirrorJobOpeningsStatusDestination {
    let client: Acme_Patientapp_V1_PatientHomeService.Client<MeshTransport>

    func forward(_ rec: MirrorJobOpeningsStatusRecord) async throws {
        _ = try await client.getPatientHome(.with {
            $0.patientHomeID = rec.status
        })
    }
}

/// Sends records to acme.admissions.v1.AdmissionCalculationService.
struct MirrorJobOpeningsStatusAdmissionCalculation: MirrorJobOpeningsStatusDestination {
    let client: Acme_Admissions_V1_AdmissionCalculationService.Client<MeshTransport>

    func forward(_ rec: MirrorJobOpeningsStatusRecord) async throws {
        _ = try await client.estimateAdmission(.with {
            $0.admission.admissionID = rec.status
            $0.admission.source = rec.correlationID
        })
    }
}

/// Sends records to acme.inventory.v1.StockItemService.
struct MirrorJobOpeningsStatusStockItem: MirrorJobOpeningsStatusDestination {
    let client: Acme_Inventory_V1_StockItemService.Client<MeshTransport>

    func forward(_ rec: MirrorJobOpeningsStatusRecord) async throws {
        _ = try await client.cloneStockItem(.with {
            $0.stockItem.stockItemID = rec.correlationID
        })
    }
}

/// Reads acme.recruiting.v1.JobOpeningService/ListJobOpenings and hands what it keeps to the sink of its kind.
enum MirrorJobOpeningsStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Recruiting_V1_JobOpeningService.Client(wrapping: mesh)
        let reply = try await upstream.listJobOpenings(.with { $0.orderBy = "live-mirror-job-openings-status" })
        let record = MirrorJobOpeningsStatusRecord(
            status: reply.result.status,
            correlationID: reply.result.correlationID
        )
        try await act("admission-calculation", record, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: MirrorJobOpeningsStatusRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "patient-home": { try await MirrorJobOpeningsStatusPatientHome(client: Acme_Patientapp_V1_PatientHomeService.Client(wrapping: mesh)).forward(rec) },
            "admission-calculation": { try await MirrorJobOpeningsStatusAdmissionCalculation(client: Acme_Admissions_V1_AdmissionCalculationService.Client(wrapping: mesh)).forward(rec) },
            "stock-item": { try await MirrorJobOpeningsStatusStockItem(client: Acme_Inventory_V1_StockItemService.Client(wrapping: mesh)).forward(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
