import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a legacy disclosure agreement.
    final class LegacyDisclosureAgreementView {
        var code: String
        var titleText: String
        var sequence: String
        var batchSize: String
        var createdAt: String
        var ceiling: String
        var procedureCode: String
        var segmentText: String
        var expiresAtText: String
        var description: String
        var statusLabel: String

        init(code: String, titleText: String, sequence: String, batchSize: String, createdAt: String, ceiling: String, procedureCode: String, segmentText: String, expiresAtText: String, description: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.sequence = sequence
            self.batchSize = batchSize
            self.createdAt = createdAt
            self.ceiling = ceiling
            self.procedureCode = procedureCode
            self.segmentText = segmentText
            self.expiresAtText = expiresAtText
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyDisclosureAgreementView(_ item: LegacyDisclosureAgreement) -> LegacyDisclosureAgreementView {
        return LegacyDisclosureAgreementView(
            code: item.code,
            titleText: item.title,
            sequence: String(item.sequence),
            batchSize: String(item.batchSize),
            createdAt: String(item.createdAt),
            ceiling: String(format: "%.2f", item.ceiling),
            procedureCode: item.procedureCode,
            segmentText: item.segment,
            expiresAtText: String(item.expiresAt),
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyDisclosureAgreementViews(_ items: [LegacyDisclosureAgreement]) -> [LegacyDisclosureAgreementView] {
        var views: [LegacyDisclosureAgreementView] = []
        for item in items {
            views.append(toLegacyDisclosureAgreementView(item))
        }
        return views
    }

    static func sumLegacyDisclosureAgreementView(_ view: LegacyDisclosureAgreementView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedSequence) + Double(parsedBatchSize) + Double(parsedCreatedAt)
    }
}
