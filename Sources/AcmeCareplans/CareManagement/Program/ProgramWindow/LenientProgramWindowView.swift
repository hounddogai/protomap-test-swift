import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a lenient program window.
    final class LenientProgramWindowView {
        var codeText: String
        var name: String
        var threshold: String
        var endsAtText: String
        var allergy: String
        var statusLabel: String

        init(codeText: String, name: String, threshold: String, endsAtText: String, allergy: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.threshold = threshold
            self.endsAtText = endsAtText
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toLenientProgramWindowView(_ item: LenientProgramWindow) -> LenientProgramWindowView {
        return LenientProgramWindowView(
            codeText: item.code,
            name: item.name,
            threshold: String(format: "%.2f", item.threshold),
            endsAtText: String(item.endsAt),
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientProgramWindowViews(_ items: [LenientProgramWindow]) -> [LenientProgramWindowView] {
        var views: [LenientProgramWindowView] = []
        for item in items {
            views.append(toLenientProgramWindowView(item))
        }
        return views
    }

    static func sumLenientProgramWindowView(_ view: LenientProgramWindowView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedThreshold + Double(parsedEndsAt)
    }
}
