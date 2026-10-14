import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set slot.
    final class OrderSetSlotView {
        var codeText: String
        var title: String
        var priorityText: String
        var bed: String
        var refills: String
        var checksum: String
        var contactEmail: String
        var pinnedText: String
        var ratio: String
        var visibleText: String
        var statusLabel: String

        init(codeText: String, title: String, priorityText: String, bed: String, refills: String, checksum: String, contactEmail: String, pinnedText: String, ratio: String, visibleText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.priorityText = priorityText
            self.bed = bed
            self.refills = refills
            self.checksum = checksum
            self.contactEmail = contactEmail
            self.pinnedText = pinnedText
            self.ratio = ratio
            self.visibleText = visibleText
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetSlotView(_ item: OrderSetSlot) -> OrderSetSlotView {
        return OrderSetSlotView(
            codeText: item.code,
            title: item.title,
            priorityText: String(item.priority),
            bed: item.bed,
            refills: String(item.refills),
            checksum: item.checksum,
            contactEmail: item.contactEmail,
            pinnedText: "\(item.pinned)",
            ratio: String(format: "%.2f", item.ratio),
            visibleText: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetSlotViews(_ items: [OrderSetSlot]) -> [OrderSetSlotView] {
        var views: [OrderSetSlotView] = []
        for item in items {
            views.append(toOrderSetSlotView(item))
        }
        return views
    }

    static func sumOrderSetSlotView(_ view: OrderSetSlotView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedPriority) + Double(parsedRefills) + parsedRatio
    }
}
