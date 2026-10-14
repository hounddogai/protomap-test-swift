import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorPendingPatientsMessage keeps of each ListPendingPatients response.
struct MirrorPendingPatientsMessageRecord {
    var message: String
    var correlationID: String
    var nextPageToken: String
}

/// Where MirrorPendingPatientsMessage hands each record.
protocol MirrorPendingPatientsMessageDestination {
    func forward(_ rec: MirrorPendingPatientsMessageRecord) async throws
}

/// Sends records to acme.seating.v1.SeatMapService.
struct MirrorPendingPatientsMessageSeatMap: MirrorPendingPatientsMessageDestination {
    let client: Acme_Seating_V1_SeatMapService.Client<MeshTransport>

    func forward(_ rec: MirrorPendingPatientsMessageRecord) async throws {
        _ = try await client.getSeatMap(.with {
            $0.seatMapID = rec.message
        })
    }
}

/// Writes records to acme.boxoffice.v1.BoxOfficeSaleQueryService.
struct MirrorPendingPatientsMessageBoxOfficeSaleQuery: MirrorPendingPatientsMessageDestination {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client<MeshTransport>

    func forward(_ rec: MirrorPendingPatientsMessageRecord) async throws {
        let request = Acme_Boxoffice_V1_FindBoxOfficeSalesRequest.with {
            $0.orderBy = rec.nextPageToken
            $0.filter.ownerID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.findBoxOfficeSales(request)
        }
    }
}

/// Writes records to acme.recruiting.v1.JobOpeningService.
struct MirrorPendingPatientsMessageJobOpening: MirrorPendingPatientsMessageDestination {
    let client: Acme_Recruiting_V1_JobOpeningService.Client<MeshTransport>

    func forward(_ rec: MirrorPendingPatientsMessageRecord) async throws {
        _ = try await client.updateJobOpening(.with {
            $0.jobOpening.notes = rec.message
            $0.jobOpening.number = rec.nextPageToken
            $0.jobOpening.jobOpeningID = rec.correlationID
        })
    }
}

/// Sends records to acme.appointments.v1.ClinicSlotCalculationService.
struct MirrorPendingPatientsMessageClinicSlotCalculation: MirrorPendingPatientsMessageDestination {
    let client: Acme_Appointments_V1_ClinicSlotCalculationService.Client<MeshTransport>

    func forward(_ rec: MirrorPendingPatientsMessageRecord) async throws {
        _ = try await client.recalculateClinicSlots(.with {
            $0.clinicSlotID = rec.nextPageToken
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct MirrorPendingPatientsMessageLogOnly: MirrorPendingPatientsMessageDestination {
    let logger = Logger(label: "acme.mirror-pending-patients-message")

    func forward(_ rec: MirrorPendingPatientsMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.patients.v1.PatientApprovalService/ListPendingPatients and hands what it keeps to the sink of its kind.
enum MirrorPendingPatientsMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Patients_V1_PatientApprovalService.Client(wrapping: mesh)
        let response = try await reader.listPendingPatients(.with { $0.orderBy = "nightly-mirror-pending-patients-message" })
        let entry = MirrorPendingPatientsMessageRecord(
            message: response.result.message,
            correlationID: response.result.correlationID,
            nextPageToken: response.pageInfo.nextPageToken
        )
        try await dispatch("job-opening", entry, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: MirrorPendingPatientsMessageRecord, _ mesh: MeshClient) async throws {
        var write: (MirrorPendingPatientsMessageRecord) async throws -> Void = MirrorPendingPatientsMessageLogOnly().forward
        switch kind {
        case "seat-map":
            write = MirrorPendingPatientsMessageSeatMap(client: Acme_Seating_V1_SeatMapService.Client(wrapping: mesh)).forward
        case "box-office-sale-query":
            write = MirrorPendingPatientsMessageBoxOfficeSaleQuery(client: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client(wrapping: mesh)).forward
        case "job-opening":
            write = MirrorPendingPatientsMessageJobOpening(client: Acme_Recruiting_V1_JobOpeningService.Client(wrapping: mesh)).forward
        case "clinic-slot-calculation":
            write = MirrorPendingPatientsMessageClinicSlotCalculation(client: Acme_Appointments_V1_ClinicSlotCalculationService.Client(wrapping: mesh)).forward
        default:
            break
        }
        try await write(rec)
    }
}
