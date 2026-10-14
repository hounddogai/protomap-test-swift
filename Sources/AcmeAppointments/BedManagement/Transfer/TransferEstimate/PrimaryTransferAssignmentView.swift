import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a primary transfer assignment.
    final class PrimaryTransferAssignmentView {
        var codeText: String
        var name: String
        var priority: String
        var specialtyText: String
        var limitText: String
        var category: String
        var batchSize: String
        var contactEmail: String
        var sequenceText: String
        var currency: String
        var statusLabel: String

        init(codeText: String, name: String, priority: String, specialtyText: String, limitText: String, category: String, batchSize: String, contactEmail: String, sequenceText: String, currency: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.priority = priority
            self.specialtyText = specialtyText
            self.limitText = limitText
            self.category = category
            self.batchSize = batchSize
            self.contactEmail = contactEmail
            self.sequenceText = sequenceText
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryTransferAssignmentView(_ item: PrimaryTransferAssignment) -> PrimaryTransferAssignmentView {
        return PrimaryTransferAssignmentView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            priority: String(item.priority),
            specialtyText: Kit.Text.truncate(item.specialty, limit: 80),
            limitText: String(item.limit),
            category: item.category,
            batchSize: String(item.batchSize),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            sequenceText: String(item.sequence),
            currency: Kit.Text.truncate(item.currency, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryTransferAssignmentViews(_ items: [PrimaryTransferAssignment]) -> [PrimaryTransferAssignmentView] {
        var views: [PrimaryTransferAssignmentView] = []
        for item in items {
            views.append(toPrimaryTransferAssignmentView(item))
        }
        return views
    }

    static func sumPrimaryTransferAssignmentView(_ view: PrimaryTransferAssignmentView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedPriority) + Double(parsedLimit) + Double(parsedBatchSize)
    }
}
