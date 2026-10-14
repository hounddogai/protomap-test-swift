import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension PatientWorkflowEndpoint {
    /// Execute the patients workflow and project its upstream replies.
    func processAdvancePatientWorkflow(_ input: Acme_Patients_V1_AdvancePatientWorkflowRequest) async throws
        -> Acme_Patients_V1_AdvancePatientWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "AdvancePatientWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        await directory.remember(tenant: input.context.tenantID, userID: input.context.actor.userID)
        let importFrame = Acme_Prescriptions_V1_StreamPrescriptionChangesRequest.with {
            $0.context = input.context
        }
        _ = try await self.prescriptionsPrescriptionSync.streamPrescriptionChanges { writer in
            try await writer.write(importFrame)
        } onResponse: { response in
            var latest = Acme_Prescriptions_V1_StreamPrescriptionChangesResponse()
            for try await message in response.messages {
                latest = message
            }
            return latest
        }
        let outbound0 = Acme_Patients_V1_DelegateMedicalRecordApprovalRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_DelegateMedicalRecordApprovalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.patient.relationshipManager.displayName
                    $0.email = input.patient.relationshipManager.email
                }
            }
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.patient.audit.createdBy
                }
            }
        }
        let envelope0 = try Google_Protobuf_Any(message: outbound0)
        let unpacked0 = try Acme_Patients_V1_DelegateMedicalRecordApprovalRequest(unpackingAny: envelope0)
        let reply0 = try await self.patientsMedicalRecordApproval.delegateMedicalRecordApproval(unpacked0)
        return Acme_Patients_V1_AdvancePatientWorkflowResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.medicalRecord.audit.etag
                }
                $0.patientID = input.patientID
                $0.relationshipManager = input.patient.relationshipManager
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.referenceIds = reply0.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processCancelPatientWorkflow(_ input: Acme_Patients_V1_CancelPatientWorkflowRequest) async throws
        -> Acme_Patients_V1_CancelPatientWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "CancelPatientWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        if let userID = await directory.user(tenant: input.context.tenantID) {
            let owner = try await self.identityUser.getUser(
                Acme_Identity_V1_GetUserRequest.with {
                    $0.context = input.context
                    $0.userID = userID
                })
            logger.debug("Prior actor", metadata: ["user": .string(owner.user.userID)])
        }
        let outbound0 = Acme_Prescriptions_V1_CommentPrescriptionApprovalRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_CommentPrescriptionApprovalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.patient.relationshipManager.userID
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.patient.contact.email
                }
            }
        }
        let json0 = try outbound0.jsonString()
        let decoded0 = try Acme_Prescriptions_V1_CommentPrescriptionApprovalRequest(jsonString: json0)
        let reply0 = try await self.prescriptionsPrescriptionApproval.commentPrescriptionApproval(decoded0)
        let outbound1 = Acme_Venues_V1_ValidateVenueRequest.forPatientWorkflowEndpointCancelPatientWorkflow1(
            input,
            reply0: reply0
        )
        let reply1 = try await self.venuesVenueValidation.validateVenue(outbound1)
        let outbound2 = Acme_Authorization_V1_CreateAccessPolicyRequest.with {
            $0.accessPolicy = Acme_Authorization_V1_AccessPolicy.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply1.venue.owner.userID
                }
            }
            $0.context = input.context
        }
        let reply2 = try await self.authorizationAccessPolicy.createAccessPolicy(
            outbound2, metadata: ["x-acme-region": .string(settings.region)]
        )
        return Acme_Patients_V1_CancelPatientWorkflowResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.attributes = input.patient.attributes
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = Projection.firstValue(
                        [
                            reply0.prescription.audit.updatedBy,
                            reply2.accessPolicy.audit.updatedBy,
                        ], default: .init())
                }
                $0.patientID = input.patientID
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = reply1.venue.address.countryCode
                }
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.outcome.message
                $0.referenceIds = reply2.result.referenceIds
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processInspectPatientWorkflow(_ input: Acme_Patients_V1_InspectPatientWorkflowRequest) async throws
        -> Acme_Patients_V1_InspectPatientWorkflowResponse
    {
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "InspectPatientWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "InspectPatientWorkflow", detail: input.context.traceID
        )
        let outbound0 = Acme_Search_V1_BrowseSearchIndexesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Search_V1_BrowseSearchIndexesRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = input.context.baggage
                $0.ownerID = input.patientID
            }
        }
        let reply0 = try await RPCOperations.call(outbound0) { request in
            try await self.searchSearchIndexQuery.browseSearchIndexes(request)
        }
        return Acme_Patients_V1_InspectPatientWorkflowResponse.with {
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.correlationID = reply0.result.correlationID
                $0.details = reply0.result.details
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processRetryPatientWorkflow(_ input: Acme_Patients_V1_RetryPatientWorkflowRequest) async throws
        -> Acme_Patients_V1_RetryPatientWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "RetryPatientWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Prescriptions_V1_EscalateRefillRequest.with {
            $0.context = Projection.read(input, at: \Acme_Patients_V1_RetryPatientWorkflowRequest.context)
            $0.refill = Acme_Prescriptions_V1_Refill.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = Projection.read(
                        input, at: \Acme_Patients_V1_RetryPatientWorkflowRequest.patient.audit.updatedAt)
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.name = Projection.read(
                        input, at: \Acme_Patients_V1_RetryPatientWorkflowRequest.patient.contact.name)
                }
            }
        }
        let reply0 = try await self.prescriptionsRefillApproval.escalateRefill(outbound0)
        return Acme_Patients_V1_RetryPatientWorkflowResponse.with {
            $0.outcome = Acme_Patients_V1_RetryPatientWorkflowResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.name = input.patient.name
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processSignalPatientWorkflow(_ input: Acme_Patients_V1_SignalPatientWorkflowRequest) async throws
        -> Acme_Patients_V1_SignalPatientWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "SignalPatientWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        let outbound0 = Acme_Patients_V1_GeneratePatientReportRequest.with {
            $0.context = input.context
            $0.patientID = input.patient.patientID
            $0.reason = input.reason
        }
        let step0: @Sendable () async throws -> Acme_Patients_V1_GeneratePatientReportResponse = {
            try await self.patientsPatientReporting.generatePatientReport(outbound0)
        }
        let reply0 = try await step0()
        return Acme_Patients_V1_SignalPatientWorkflowResponse.with {
            $0.outcome = Acme_Patients_V1_SignalPatientWorkflowResponse.Outcome.with {
                $0.message = reply0.result.message
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.contact = input.patient.contact
                $0.patientID = input.patientID
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.message = reply0.result.message
                $0.status = "ok"
            }
        }
    }

    /// Execute the patients workflow and project its upstream replies.
    func processStartPatientWorkflow(_ input: Acme_Patients_V1_StartPatientWorkflowRequest) async throws
        -> Acme_Patients_V1_StartPatientWorkflowResponse
    {
        logger.debug("Audit detail", metadata: ["detail": .string(input.details.initiatedBy)])
        try await store.recordAction(
            tenant: input.context.tenantID, kind: "patient",
            action: "audit", detail: input.details.initiatedBy
        )
        guard !input.context.tenantID.isEmpty else {
            throw RPCError(code: .invalidArgument, message: "A tenant is required")
        }
        try Task.checkCancellation()
        logger.info(
            "StartPatientWorkflow",
            metadata: [
                "tenant": .string(input.context.tenantID), "region": .string(settings.region),
            ])
        let record = try PatientRecord(input.patient, tenant: input.context.tenantID)
        try await store.save(record.stored)
        var outbound0 = Acme_Ledger_V1_SummarizeLedgerAccountsRequest()
        outbound0.annotations = input.annotations
        outbound0.context = input.context
        outbound0.details = Acme_Ledger_V1_SummarizeLedgerAccountsRequest.Details.with {
            $0.filters = input.details.parameters
            $0.period = input.patient.preferences.quietHours
        }
        outbound0.reason = input.reason
        let reply0 = try await self.ledgerLedgerAccountQuery.summarizeLedgerAccounts(outbound0)
        let outbound1 = Acme_Patients_V1_DelegateMedicalRecordApprovalRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_DelegateMedicalRecordApprovalRequest.Details.with {
                $0.approver = Acme_Identity_V1_UserRef.with {
                    $0.userID = input.patient.relationshipManager.userID
                }
            }
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.patient.contact.email
                }
            }
        }
        let step1: @Sendable () async throws -> Acme_Patients_V1_DelegateMedicalRecordApprovalResponse = {
            try await self.patientsMedicalRecordApproval.delegateMedicalRecordApproval(outbound1)
        }
        let reply1 = try await step1()
        return Acme_Patients_V1_StartPatientWorkflowResponse.with {
            $0.outcome = Acme_Patients_V1_StartPatientWorkflowResponse.Outcome.with {
                $0.status = reply0.result.status
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.patientID = input.patientID
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply1.medicalRecord.billingAddress.postalCode
                }
                $0.status = input.patient.status
            }
            $0.result = Acme_Common_V1_OperationResult.with {
                $0.status = "ok"
            }
        }
    }
}
