import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result bundle.
    final class ResultBundleView {
        var code: String
        var title: String
        var ratioText: String
        var capacity: String
        var quantity: String
        var allergy: String
        var currency: String
        var versionText: String
        var notes: String
        var statusLabel: String

        init(code: String, title: String, ratioText: String, capacity: String, quantity: String, allergy: String, currency: String, versionText: String, notes: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ratioText = ratioText
            self.capacity = capacity
            self.quantity = quantity
            self.allergy = allergy
            self.currency = currency
            self.versionText = versionText
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toResultBundleView(_ item: ResultBundle) -> ResultBundleView {
        return ResultBundleView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 40),
            ratioText: String(format: "%.2f", item.ratio),
            capacity: String(item.capacity),
            quantity: String(item.quantity),
            allergy: item.allergy,
            currency: Kit.Text.truncate(item.currency, limit: 80),
            versionText: String(item.version),
            notes: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultBundleViews(_ items: [ResultBundle]) -> [ResultBundleView] {
        var views: [ResultBundleView] = []
        for item in items {
            views.append(toResultBundleView(item))
        }
        return views
    }

    static func sumResultBundleView(_ view: ResultBundleView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedRatio + Double(parsedCapacity) + Double(parsedQuantity)
    }
}
