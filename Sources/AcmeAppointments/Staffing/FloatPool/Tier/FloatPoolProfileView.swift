import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool profile.
    final class FloatPoolProfileView {
        var code: String
        var labelText: String
        var maximumText: String
        var bedText: String
        var approved: String
        var retries: String
        var rate: String
        var statusLabel: String

        init(code: String, labelText: String, maximumText: String, bedText: String, approved: String, retries: String, rate: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.maximumText = maximumText
            self.bedText = bedText
            self.approved = approved
            self.retries = retries
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolProfileView(_ item: FloatPoolProfile) -> FloatPoolProfileView {
        return FloatPoolProfileView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            maximumText: String(format: "%.2f", item.maximum),
            bedText: item.bed,
            approved: "\(item.approved)",
            retries: String(item.retries),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolProfileViews(_ items: [FloatPoolProfile]) -> [FloatPoolProfileView] {
        var views: [FloatPoolProfileView] = []
        for item in items {
            views.append(toFloatPoolProfileView(item))
        }
        return views
    }

    static func sumFloatPoolProfileView(_ view: FloatPoolProfileView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedMaximum + Double(parsedRetries) + parsedRate
    }
}
