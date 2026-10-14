import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier request.
    final class CourierRequestView {
        var code: String
        var title: String
        var maximumText: String
        var phone: String
        var visible: String
        var statusLabel: String

        init(code: String, title: String, maximumText: String, phone: String, visible: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.maximumText = maximumText
            self.phone = phone
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toCourierRequestView(_ item: CourierRequest) -> CourierRequestView {
        return CourierRequestView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            maximumText: String(format: "%.2f", item.maximum),
            phone: item.phone,
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierRequestViews(_ items: [CourierRequest]) -> [CourierRequestView] {
        var views: [CourierRequestView] = []
        for item in items {
            views.append(toCourierRequestView(item))
        }
        return views
    }

    static func sumCourierRequestView(_ view: CourierRequestView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMaximum
    }
}
