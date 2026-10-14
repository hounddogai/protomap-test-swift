import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime agreement.
    final class OvertimeAgreementView {
        var code: String
        var title: String
        var checksum: String
        var floorValue: String
        var rate: String
        var statusLabel: String

        init(code: String, title: String, checksum: String, floorValue: String, rate: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.floorValue = floorValue
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeAgreementView(_ item: OvertimeAgreement) -> OvertimeAgreementView {
        return OvertimeAgreementView(
            code: item.code,
            title: item.title,
            checksum: item.checksum,
            floorValue: String(format: "%.2f", item.floorValue),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeAgreementViews(_ items: [OvertimeAgreement]) -> [OvertimeAgreementView] {
        var views: [OvertimeAgreementView] = []
        for item in items {
            views.append(toOvertimeAgreementView(item))
        }
        return views
    }

    static func sumOvertimeAgreementView(_ view: OvertimeAgreementView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedFloorValue + parsedRate
    }
}
