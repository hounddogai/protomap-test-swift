import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a global courier mapping.
    final class GlobalCourierMappingView {
        var code: String
        var title: String
        var activeText: String
        var expiresAt: String
        var acuity: String
        var clinicianID: String
        var marginText: String
        var payer: String
        var dosageMgText: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, title: String, activeText: String, expiresAt: String, acuity: String, clinicianID: String, marginText: String, payer: String, dosageMgText: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.activeText = activeText
            self.expiresAt = expiresAt
            self.acuity = acuity
            self.clinicianID = clinicianID
            self.marginText = marginText
            self.payer = payer
            self.dosageMgText = dosageMgText
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCourierMappingView(_ item: GlobalCourierMapping) -> GlobalCourierMappingView {
        return GlobalCourierMappingView(
            code: item.code,
            title: item.title,
            activeText: "\(item.active)",
            expiresAt: String(item.expiresAt),
            acuity: String(item.acuity),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            marginText: String(format: "%.2f", item.margin),
            payer: item.payer,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCourierMappingViews(_ items: [GlobalCourierMapping]) -> [GlobalCourierMappingView] {
        var views: [GlobalCourierMappingView] = []
        for item in items {
            views.append(toGlobalCourierMappingView(item))
        }
        return views
    }

    static func sumGlobalCourierMappingView(_ view: GlobalCourierMappingView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedAcuity) + parsedMargin
    }
}
