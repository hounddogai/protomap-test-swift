import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive risk score item is in its life cycle.
    enum AdaptiveRiskScoreItemStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a adaptive risk score item and its current status.
    final class AdaptiveRiskScoreItem {
        var code: String
        var name: String
        var reviewer: String
        var minimum: Double
        var threshold: Double
        var diagnosisCode: String
        var notes: String
        var procedureCode: String
        var timezone: String
        var attributes: [String: String]
        var summary: String
        var status: AdaptiveRiskScoreItemStatus

        init(code: String, name: String, reviewer: String, minimum: Double, threshold: Double, diagnosisCode: String, notes: String, procedureCode: String, timezone: String, attributes: [String: String], summary: String, status: AdaptiveRiskScoreItemStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.minimum = minimum
            self.threshold = threshold
            self.diagnosisCode = diagnosisCode
            self.notes = notes
            self.procedureCode = procedureCode
            self.timezone = timezone
            self.attributes = attributes
            self.summary = summary
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveRiskScoreItemStatus) -> Bool {
            switch status {
            case .created:
                return next == AdaptiveRiskScoreItemStatus.validated
            case .validated:
                return next == AdaptiveRiskScoreItemStatus.retired
            case .published:
                return next == AdaptiveRiskScoreItemStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveRiskScoreItemStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive risk score item \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive risk score item") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedValue() -> Double {
            return ((threshold - minimum) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveRiskScoreItem {
            return AdaptiveRiskScoreItem(
                code: code,
                name: name,
                reviewer: reviewer,
                minimum: minimum,
                threshold: threshold,
                diagnosisCode: diagnosisCode,
                notes: notes,
                procedureCode: procedureCode,
                timezone: timezone,
                attributes: attributes,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive risk score item in status created.
    static func newAdaptiveRiskScoreItem(_ code: String, name: String) -> AdaptiveRiskScoreItem {
        return AdaptiveRiskScoreItem(
            code: code,
            name: name,
            reviewer: "",
            minimum: 0.0,
            threshold: 0.0,
            diagnosisCode: "",
            notes: "",
            procedureCode: "",
            timezone: "",
            attributes: [:],
            summary: "",
            status: AdaptiveRiskScoreItemStatus.created
        )
    }
}
