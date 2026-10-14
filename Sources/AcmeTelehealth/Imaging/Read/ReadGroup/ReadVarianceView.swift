import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read variance.
    final class ReadVarianceView {
        var code: String
        var nameText: String
        var segment: String
        var visitMinutes: String
        var ratioText: String
        var statusLabel: String

        init(code: String, nameText: String, segment: String, visitMinutes: String, ratioText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.segment = segment
            self.visitMinutes = visitMinutes
            self.ratioText = ratioText
            self.statusLabel = statusLabel
        }
    }

    static func toReadVarianceView(_ item: ReadVariance) -> ReadVarianceView {
        return ReadVarianceView(
            code: item.code,
            nameText: item.name,
            segment: item.segment,
            visitMinutes: String(item.visitMinutes),
            ratioText: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadVarianceViews(_ items: [ReadVariance]) -> [ReadVarianceView] {
        var views: [ReadVarianceView] = []
        for item in items {
            views.append(toReadVarianceView(item))
        }
        return views
    }

    static func sumReadVarianceView(_ view: ReadVarianceView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedVisitMinutes) + parsedRatio
    }
}
