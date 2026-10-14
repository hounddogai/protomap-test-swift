import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense manifest.
    final class DispenseManifestView {
        var code: String
        var name: String
        var patientRefText: String
        var region: String
        var visibleText: String
        var score: String
        var thresholdText: String
        var facility: String
        var specialty: String
        var version: String
        var locale: String
        var statusLabel: String

        init(code: String, name: String, patientRefText: String, region: String, visibleText: String, score: String, thresholdText: String, facility: String, specialty: String, version: String, locale: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.patientRefText = patientRefText
            self.region = region
            self.visibleText = visibleText
            self.score = score
            self.thresholdText = thresholdText
            self.facility = facility
            self.specialty = specialty
            self.version = version
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseManifestView(_ item: DispenseManifest) -> DispenseManifestView {
        return DispenseManifestView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            patientRefText: item.patientRef,
            region: item.region,
            visibleText: "\(item.visible)",
            score: String(format: "%.2f", item.score),
            thresholdText: String(format: "%.2f", item.threshold),
            facility: item.facility,
            specialty: item.specialty,
            version: String(item.version),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseManifestViews(_ items: [DispenseManifest]) -> [DispenseManifestView] {
        var views: [DispenseManifestView] = []
        for item in items {
            views.append(toDispenseManifestView(item))
        }
        return views
    }

    static func sumDispenseManifestView(_ view: DispenseManifestView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedScore + parsedThreshold + Double(parsedVersion)
    }
}
