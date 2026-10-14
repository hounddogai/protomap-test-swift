import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorDeliveryNotes keeps of each CloneDelivery response.
struct MirrorDeliveryNotesRecord {
    var notes: String
    var status: String
    var number: String
    var deliveryID: String
}

/// Where MirrorDeliveryNotes hands each record.
protocol MirrorDeliveryNotesDestination {
    func apply(_ rec: MirrorDeliveryNotesRecord) async throws
}

/// Hands records to acme.telehealth.v1.VideoVisitCalculationService.
struct MirrorDeliveryNotesVideoVisitCalculation: MirrorDeliveryNotesDestination {
    let client: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>

    func apply(_ rec: MirrorDeliveryNotesRecord) async throws {
        _ = try await client.estimateVideoVisit(.with {
            $0.videoVisit.title = rec.notes
            $0.videoVisit.videoVisitID = rec.number
            $0.details.currencyCode = rec.status
        })
    }
}

/// Sends records to acme.patients.v1.PatientReportingService.
struct MirrorDeliveryNotesPatientReporting: MirrorDeliveryNotesDestination {
    let client: Acme_Patients_V1_PatientReportingService.Client<MeshTransport>

    func apply(_ rec: MirrorDeliveryNotesRecord) async throws {
        _ = try await client.fetchPatientReport(.with {
            $0.patientID = rec.notes
        })
    }
}

/// Sends records to acme.careplans.v1.CareGoalLifecycleService.
struct MirrorDeliveryNotesCareGoalLifecycle: MirrorDeliveryNotesDestination {
    let client: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>

    func apply(_ rec: MirrorDeliveryNotesRecord) async throws {
        _ = try await client.terminateCareGoal(.with {
            $0.reason = rec.deliveryID
        })
    }
}

/// Reads acme.deliveries.v1.DeliveryService/CloneDelivery and hands what it keeps to the sink of its kind.
enum MirrorDeliveryNotes {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Deliveries_V1_DeliveryService.Client(wrapping: mesh)
        let reply = try await origin.cloneDelivery(.with { $0.requestID = "live-mirror-delivery-notes" })
        let entry = MirrorDeliveryNotesRecord(
            notes: reply.delivery.notes,
            status: reply.result.status,
            number: reply.delivery.number,
            deliveryID: reply.delivery.deliveryID
        )
        let sinks: [any MirrorDeliveryNotesDestination] = [
            MirrorDeliveryNotesVideoVisitCalculation(client: Acme_Telehealth_V1_VideoVisitCalculationService.Client(wrapping: mesh)),
            MirrorDeliveryNotesPatientReporting(client: Acme_Patients_V1_PatientReportingService.Client(wrapping: mesh)),
            MirrorDeliveryNotesCareGoalLifecycle(client: Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: mesh)),
        ]
        try await sinks[1].apply(entry)
    }
}
