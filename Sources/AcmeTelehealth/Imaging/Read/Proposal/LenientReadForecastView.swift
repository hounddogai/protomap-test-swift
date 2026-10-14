import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a lenient read forecast.
    final class LenientReadForecastView {
        var codeText: String
        var labelText: String
        var sequenceText: String
        var visible: String
        var active: String
        var statusLabel: String

        init(codeText: String, labelText: String, sequenceText: String, visible: String, active: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.sequenceText = sequenceText
            self.visible = visible
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toLenientReadForecastView(_ item: LenientReadForecast) -> LenientReadForecastView {
        return LenientReadForecastView(
            codeText: item.code,
            labelText: item.label,
            sequenceText: String(item.sequence),
            visible: "\(item.visible)",
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientReadForecastViews(_ items: [LenientReadForecast]) -> [LenientReadForecastView] {
        var views: [LenientReadForecastView] = []
        for item in items {
            views.append(toLenientReadForecastView(item))
        }
        return views
    }

    static func sumLenientReadForecastView(_ view: LenientReadForecastView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedSequence)
    }
}
