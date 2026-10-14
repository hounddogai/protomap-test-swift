import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a lenient revocation group.
    final class LenientRevocationGroupView {
        var codeText: String
        var name: String
        var diagnosisCodeText: String
        var graceDays: String
        var version: String
        var capacity: String
        var facility: String
        var threshold: String
        var allergy: String
        var expiresAt: String
        var weight: String
        var statusLabel: String

        init(codeText: String, name: String, diagnosisCodeText: String, graceDays: String, version: String, capacity: String, facility: String, threshold: String, allergy: String, expiresAt: String, weight: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.diagnosisCodeText = diagnosisCodeText
            self.graceDays = graceDays
            self.version = version
            self.capacity = capacity
            self.facility = facility
            self.threshold = threshold
            self.allergy = allergy
            self.expiresAt = expiresAt
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toLenientRevocationGroupView(_ item: LenientRevocationGroup) -> LenientRevocationGroupView {
        return LenientRevocationGroupView(
            codeText: item.code,
            name: item.name,
            diagnosisCodeText: item.diagnosisCode,
            graceDays: String(item.graceDays),
            version: String(item.version),
            capacity: String(item.capacity),
            facility: item.facility,
            threshold: String(format: "%.2f", item.threshold),
            allergy: item.allergy,
            expiresAt: String(item.expiresAt),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientRevocationGroupViews(_ items: [LenientRevocationGroup]) -> [LenientRevocationGroupView] {
        var views: [LenientRevocationGroupView] = []
        for item in items {
            views.append(toLenientRevocationGroupView(item))
        }
        return views
    }

    static func sumLenientRevocationGroupView(_ view: LenientRevocationGroupView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedVersion) + Double(parsedCapacity)
    }
}
