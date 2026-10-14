import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension PatientHomeQueryEndpoint {
    /// Execute the patientapp workflow and project its upstream replies.
    func processBrowsePatientHomes(_ input: Acme_Patientapp_V1_BrowsePatientHomesRequest) async throws
        -> Acme_Patientapp_V1_BrowsePatientHomesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "BrowsePatientHomes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "BrowsePatientHomes", detail: input.context.traceID
        )
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        try followUps.submit(
            Acme_Identity_V1_GetUserRequest.with {
                $0.context = input.context
                $0.userID = input.context.actor.userID
            })
        let importFrame = Acme_Prescriptions_V1_StreamMedicationChangesRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsMedicationSync.streamMedicationChanges { writer in
            try await writer.write(importFrame)
        } onResponse: { response in
            var latest = Acme_Prescriptions_V1_StreamMedicationChangesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        let outbound0 = Acme_Prescriptions_V1_PushPrescriptionRequest.with {
            $0.context = input.context
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.filter.createdAfter
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.context.actor.email
                }
                $0.lines = [
                    Acme_Prescriptions_V1_PrescriptionLine.with {
                        $0.attributes = input.filter.labels
                    }
                ]
            }
        }
        let reply0 = try await self.prescriptionsPrescriptionSync.pushPrescription(outbound0)
        return Acme_Patientapp_V1_BrowsePatientHomesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.outcome.message
                $0.status = reply0.result.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processCountPatientHomes(_ input: Acme_Patientapp_V1_CountPatientHomesRequest) async throws
        -> Acme_Patientapp_V1_CountPatientHomesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CountPatientHomes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "CountPatientHomes", detail: input.context.traceID
        )
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Patientapp_V1_UnsubscribePatientHomeUpdatesRequest.with {
            $0.annotations = input.context.baggage
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_UnsubscribePatientHomeUpdatesRequest.Details.with {
                $0.recipient = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.variables = input.filter.labels
            }
        }
        async let remote0 = self.patientappPatientHomeNotification.unsubscribePatientHomeUpdates(outbound0)
        async let persisted0 = store.count(tenant: input.context.tenantID)
        let (reply0, count0) = try await (remote0, persisted0)
        logger.debug("Parallel read", metadata: ["records": .stringConvertible(count0)])
        return Acme_Patientapp_V1_CountPatientHomesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processExportPatientHomes(_ input: Acme_Patientapp_V1_ExportPatientHomesRequest) async throws
        -> Acme_Patientapp_V1_ExportPatientHomesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.destinationUri)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.destinationUri
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "ExportPatientHomes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "ExportPatientHomes", detail: input.context.traceID
        )
        let outbound0 = Acme_Prescriptions_V1_PushMedicationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
        let reply0 = try await self.exportPatientHomesStep0.execute(outbound0)
        let outbound1 = Acme_Documents_V1_BatchGetDocumentsRequest.with {
            $0.context = input.context
        }
        let port1 = RPCOperations.port { (request: Acme_Documents_V1_BatchGetDocumentsRequest) in
            try await self.documentsDocument.batchGetDocuments(request)
        }
        let reply1 = try await port1.execute(outbound1)
        let outbound2 = Acme_Patients_V1_CommentAllergyApprovalRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.measurements = [
                    Acme_Patients_V1_AllergyMeasurement.with {
                        $0.unit = reply0.medication.dimensions.unit
                    }
                ]
            }
            $0.context = input.context
        }
        let reply2 = try await self.exportPatientHomesStep2(outbound2)
        let outbound3 = Acme_Audit_V1_FindAuditEventsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Audit_V1_FindAuditEventsRequest.Filter.with {
                $0.labels = input.filter.labels
            }
        }
        guard let execute3 = self.exportPatientHomesStep3[settings.region] ?? self.exportPatientHomesStep3["primary"]
        else {
            throw RPCError(code: .failedPrecondition, message: "No route for the selected region")
        }
        let reply3 = try await execute3(outbound3)
        return Acme_Patientapp_V1_ExportPatientHomesResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = reply2.allergy.subject.email
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.medication.audit.etag
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = Projection.firstValue(
                    [
                        reply2.result.correlationID,
                        reply3.result.correlationID,
                    ], default: .init())
                $0.details = reply1.result.details
                $0.status = reply1.result.status
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processFindPatientHomes(_ input: Acme_Patientapp_V1_FindPatientHomesRequest) async throws
        -> Acme_Patientapp_V1_FindPatientHomesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "FindPatientHomes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "FindPatientHomes", detail: input.context.traceID
        )
        return Acme_Patientapp_V1_FindPatientHomesResponse.with {
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processLookupPatientHome(_ input: Acme_Patientapp_V1_LookupPatientHomeRequest) async throws
        -> Acme_Patientapp_V1_LookupPatientHomeResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "LookupPatientHome",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "LookupPatientHome", detail: input.context.traceID
        )
        let outbound0 = Acme_Audit_V1_ListAuditEventsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Audit_V1_ListAuditEventsRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.ownerID = input.patientHomeID
            }
        }
        let reply0 = try await self.auditAuditEvent.listAuditEvents(outbound0)
        return Acme_Patientapp_V1_LookupPatientHomeResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.patientHomeID = input.patientHomeID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.details = reply0.result.details
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processPeekPatientHome(_ input: Acme_Patientapp_V1_PeekPatientHomeRequest) async throws
        -> Acme_Patientapp_V1_PeekPatientHomeResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "PeekPatientHome",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "PeekPatientHome", detail: input.context.traceID
        )
        return Acme_Patientapp_V1_PeekPatientHomeResponse.with {
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.patientHomeID = input.patientHomeID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patientapp workflow and project its upstream replies.
    func processSuggestPatientHomes(_ input: Acme_Patientapp_V1_SuggestPatientHomesRequest) async throws
        -> Acme_Patientapp_V1_SuggestPatientHomesResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.filter.ownerID)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "audit", detail: input.filter.ownerID
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SuggestPatientHomes",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient_home",
            action: "SuggestPatientHomes", detail: input.context.traceID
        )
        let outbound0 = Acme_Patientapp_V1_NotifyPatientHomeWatchersRequest.with {
            $0.annotations = input.filter.labels
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_NotifyPatientHomeWatchersRequest.Details.with {
                $0.recipient = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.variables = input.context.baggage
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Patientapp_V1_NotifyPatientHomeWatchersRequest(unpackingAny: envelope0)
        let reply0 = try await self.patientappPatientHomeNotification.notifyPatientHomeWatchers(unpacked0)
        return Acme_Patientapp_V1_SuggestPatientHomesResponse.with {
            $0.patientHomes = [
                Acme_Patientapp_V1_PatientHome.with {
                    $0.assignee = Acme_Identity_V1_UserRef.with {
                        $0.email = reply0.patientHome.assignee.email
                    }
                }
            ]
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
