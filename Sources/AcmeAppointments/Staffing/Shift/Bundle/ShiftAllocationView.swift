import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift allocation.
    final class ShiftAllocationView {
        var codeText: String
        var title: String
        var source: String
        var weight: String
        var createdAtText: String
        var startsAt: String
        var notesText: String
        var sequence: String
        var procedureCode: String
        var statusLabel: String

        init(codeText: String, title: String, source: String, weight: String, createdAtText: String, startsAt: String, notesText: String, sequence: String, procedureCode: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.source = source
            self.weight = weight
            self.createdAtText = createdAtText
            self.startsAt = startsAt
            self.notesText = notesText
            self.sequence = sequence
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toShiftAllocationView(_ item: ShiftAllocation) -> ShiftAllocationView {
        return ShiftAllocationView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            source: Kit.Text.truncate(item.source, limit: 40),
            weight: String(format: "%.2f", item.weight),
            createdAtText: String(item.createdAt),
            startsAt: String(item.startsAt),
            notesText: Kit.Text.truncate(item.notes, limit: 120),
            sequence: String(item.sequence),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftAllocationViews(_ items: [ShiftAllocation]) -> [ShiftAllocationView] {
        var views: [ShiftAllocationView] = []
        for item in items {
            views.append(toShiftAllocationView(item))
        }
        return views
    }

    static func sumShiftAllocationView(_ view: ShiftAllocationView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedWeight + Double(parsedCreatedAt) + Double(parsedStartsAt)
    }
}
