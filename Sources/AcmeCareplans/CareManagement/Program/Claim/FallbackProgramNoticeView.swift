import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a fallback program notice.
    final class FallbackProgramNoticeView {
        var codeText: String
        var label: String
        var floorValueText: String
        var acuity: String
        var country: String
        var statusLabel: String

        init(codeText: String, label: String, floorValueText: String, acuity: String, country: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.floorValueText = floorValueText
            self.acuity = acuity
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackProgramNoticeView(_ item: FallbackProgramNotice) -> FallbackProgramNoticeView {
        return FallbackProgramNoticeView(
            codeText: item.code,
            label: item.label,
            floorValueText: String(format: "%.2f", item.floorValue),
            acuity: String(item.acuity),
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackProgramNoticeViews(_ items: [FallbackProgramNotice]) -> [FallbackProgramNoticeView] {
        var views: [FallbackProgramNoticeView] = []
        for item in items {
            views.append(toFallbackProgramNoticeView(item))
        }
        return views
    }

    static func sumFallbackProgramNoticeView(_ view: FallbackProgramNoticeView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedFloorValue + Double(parsedAcuity)
    }
}
