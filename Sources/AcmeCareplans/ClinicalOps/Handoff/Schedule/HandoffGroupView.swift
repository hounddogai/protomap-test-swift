import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff group.
    final class HandoffGroupView {
        var code: String
        var title: String
        var specialtyText: String
        var expiresAtText: String
        var floorValue: String
        var reviewerText: String
        var statusLabel: String

        init(code: String, title: String, specialtyText: String, expiresAtText: String, floorValue: String, reviewerText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.specialtyText = specialtyText
            self.expiresAtText = expiresAtText
            self.floorValue = floorValue
            self.reviewerText = reviewerText
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffGroupView(_ item: HandoffGroup) -> HandoffGroupView {
        return HandoffGroupView(
            code: item.code,
            title: item.title,
            specialtyText: item.specialty,
            expiresAtText: String(item.expiresAt),
            floorValue: String(format: "%.2f", item.floorValue),
            reviewerText: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffGroupViews(_ items: [HandoffGroup]) -> [HandoffGroupView] {
        var views: [HandoffGroupView] = []
        for item in items {
            views.append(toHandoffGroupView(item))
        }
        return views
    }

    static func sumHandoffGroupView(_ view: HandoffGroupView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedExpiresAt) + parsedFloorValue
    }
}
