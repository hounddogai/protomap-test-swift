import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study draft.
    final class StudyDraftView {
        var code: String
        var name: String
        var maximumText: String
        var unit: String
        var wardText: String
        var refills: String
        var clinicianIDText: String
        var statusLabel: String

        init(code: String, name: String, maximumText: String, unit: String, wardText: String, refills: String, clinicianIDText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.maximumText = maximumText
            self.unit = unit
            self.wardText = wardText
            self.refills = refills
            self.clinicianIDText = clinicianIDText
            self.statusLabel = statusLabel
        }
    }

    static func toStudyDraftView(_ item: StudyDraft) -> StudyDraftView {
        return StudyDraftView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 80),
            maximumText: String(format: "%.2f", item.maximum),
            unit: item.unit,
            wardText: item.ward,
            refills: String(item.refills),
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyDraftViews(_ items: [StudyDraft]) -> [StudyDraftView] {
        var views: [StudyDraftView] = []
        for item in items {
            views.append(toStudyDraftView(item))
        }
        return views
    }

    static func sumStudyDraftView(_ view: StudyDraftView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedMaximum + Double(parsedRefills)
    }
}
