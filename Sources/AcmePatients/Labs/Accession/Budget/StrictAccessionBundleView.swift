import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a strict accession bundle.
    final class StrictAccessionBundleView {
        var code: String
        var name: String
        var visibleText: String
        var patientRefText: String
        var visitMinutes: String
        var startsAt: String
        var bed: String
        var locale: String
        var statusLabel: String

        init(code: String, name: String, visibleText: String, patientRefText: String, visitMinutes: String, startsAt: String, bed: String, locale: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visibleText = visibleText
            self.patientRefText = patientRefText
            self.visitMinutes = visitMinutes
            self.startsAt = startsAt
            self.bed = bed
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toStrictAccessionBundleView(_ item: StrictAccessionBundle) -> StrictAccessionBundleView {
        return StrictAccessionBundleView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            visibleText: "\(item.visible)",
            patientRefText: item.patientRef,
            visitMinutes: String(item.visitMinutes),
            startsAt: String(item.startsAt),
            bed: Kit.Text.truncate(item.bed, limit: 64),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictAccessionBundleViews(_ items: [StrictAccessionBundle]) -> [StrictAccessionBundleView] {
        var views: [StrictAccessionBundleView] = []
        for item in items {
            views.append(toStrictAccessionBundleView(item))
        }
        return views
    }

    static func sumStrictAccessionBundleView(_ view: StrictAccessionBundleView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedStartsAt)
    }
}
