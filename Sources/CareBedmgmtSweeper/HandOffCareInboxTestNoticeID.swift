import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffCareInboxTestNoticeID keeps of each SendCareInboxTestNotice response.
struct HandOffCareInboxTestNoticeIDRecord {
    var correlationID: String
    var referenceID: String
}

/// Where HandOffCareInboxTestNoticeID hands each record.
protocol HandOffCareInboxTestNoticeIDDestination {
    func send(_ rec: HandOffCareInboxTestNoticeIDRecord) async throws
}

/// Passes records to acme.drivers.v1.DriverService.
struct HandOffCareInboxTestNoticeIDDriver: HandOffCareInboxTestNoticeIDDestination {
    let client: Acme_Drivers_V1_DriverService.Client<MeshTransport>

    func send(_ rec: HandOffCareInboxTestNoticeIDRecord) async throws {
        _ = try await client.updateDriver(.with {
            $0.driver.driverID = rec.referenceID
        })
    }
}

/// Hands records to acme.telehealth.v1.VisitNoteValidationService.
struct HandOffCareInboxTestNoticeIDVisitNoteValidation: HandOffCareInboxTestNoticeIDDestination {
    let client: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>

    func send(_ rec: HandOffCareInboxTestNoticeIDRecord) async throws {
        _ = try await client.explainVisitNoteDecision(.with {
            $0.visitNote.visitNoteID = rec.correlationID
            $0.visitNoteID = rec.referenceID
        })
    }
}

/// Reads acme.patientapp.v1.CareInboxNotificationService/SendCareInboxTestNotice and hands what it keeps to the sink of its kind.
enum HandOffCareInboxTestNoticeID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patientapp_V1_CareInboxNotificationService.Client(wrapping: mesh)
        let reply = try await origin.sendCareInboxTestNotice(.with { $0.careInboxID = "current-hand-off-care-inbox-test-notice-id" })
        let record = HandOffCareInboxTestNoticeIDRecord(
            correlationID: reply.result.correlationID,
            referenceID: reply.outcome.referenceID
        )
        let sinks: [String: any HandOffCareInboxTestNoticeIDDestination] = [
            "driver": HandOffCareInboxTestNoticeIDDriver(client: Acme_Drivers_V1_DriverService.Client(wrapping: mesh)),
            "visit-note-validation": HandOffCareInboxTestNoticeIDVisitNoteValidation(client: Acme_Telehealth_V1_VisitNoteValidationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "visit-note-validation" {
                continue
            }
            try await sink.send(record)
        }
    }
}
