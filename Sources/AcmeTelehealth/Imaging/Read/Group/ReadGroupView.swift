import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read group.
    final class ReadGroupView {
        var codeText: String
        var nameText: String
        var contactEmail: String
        var copay: String
        var notes: String
        var statusLabel: String

        init(codeText: String, nameText: String, contactEmail: String, copay: String, notes: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.contactEmail = contactEmail
            self.copay = copay
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toReadGroupView(_ item: ReadGroup) -> ReadGroupView {
        return ReadGroupView(
            codeText: item.code,
            nameText: item.name,
            contactEmail: item.contactEmail,
            copay: String(format: "%.2f", item.copay),
            notes: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadGroupViews(_ items: [ReadGroup]) -> [ReadGroupView] {
        var views: [ReadGroupView] = []
        for item in items {
            views.append(toReadGroupView(item))
        }
        return views
    }

    static func sumReadGroupView(_ view: ReadGroupView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
