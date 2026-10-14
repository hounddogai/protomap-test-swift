import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a global care gap notice.
    final class GlobalCareGapNoticeView {
        var code: String
        var name: String
        var marginText: String
        var archivedText: String
        var dosageMgText: String
        var statusLabel: String

        init(code: String, name: String, marginText: String, archivedText: String, dosageMgText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.marginText = marginText
            self.archivedText = archivedText
            self.dosageMgText = dosageMgText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCareGapNoticeView(_ item: GlobalCareGapNotice) -> GlobalCareGapNoticeView {
        return GlobalCareGapNoticeView(
            code: item.code,
            name: item.name,
            marginText: String(format: "%.2f", item.margin),
            archivedText: "\(item.archived)",
            dosageMgText: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCareGapNoticeViews(_ items: [GlobalCareGapNotice]) -> [GlobalCareGapNoticeView] {
        var views: [GlobalCareGapNoticeView] = []
        for item in items {
            views.append(toGlobalCareGapNoticeView(item))
        }
        return views
    }

    static func sumGlobalCareGapNoticeView(_ view: GlobalCareGapNoticeView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedMargin + parsedDosageMg
    }
}
