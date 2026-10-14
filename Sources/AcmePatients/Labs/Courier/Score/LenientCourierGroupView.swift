import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a lenient courier group.
    final class LenientCourierGroupView {
        var code: String
        var title: String
        var bed: String
        var summaryText: String
        var clinicianID: String
        var pinnedText: String
        var floorValueText: String
        var statusLabel: String

        init(code: String, title: String, bed: String, summaryText: String, clinicianID: String, pinnedText: String, floorValueText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.bed = bed
            self.summaryText = summaryText
            self.clinicianID = clinicianID
            self.pinnedText = pinnedText
            self.floorValueText = floorValueText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientCourierGroupView(_ item: LenientCourierGroup) -> LenientCourierGroupView {
        return LenientCourierGroupView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            bed: item.bed,
            summaryText: item.summary,
            clinicianID: item.clinicianID,
            pinnedText: "\(item.pinned)",
            floorValueText: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientCourierGroupViews(_ items: [LenientCourierGroup]) -> [LenientCourierGroupView] {
        var views: [LenientCourierGroupView] = []
        for item in items {
            views.append(toLenientCourierGroupView(item))
        }
        return views
    }

    static func sumLenientCourierGroupView(_ view: LenientCourierGroupView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
