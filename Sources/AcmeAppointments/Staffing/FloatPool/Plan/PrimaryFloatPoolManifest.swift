import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary float pool manifest is in its life cycle.
    enum PrimaryFloatPoolManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One primary float pool manifest, with what the planners need to act on it.
    final class PrimaryFloatPoolManifest {
        var code: String
        var label: String
        var cost: Double
        var windowDays: Int
        var score: Double
        var segment: String
        var diagnosisCode: String
        var status: PrimaryFloatPoolManifestStatus

        init(code: String, label: String, cost: Double, windowDays: Int, score: Double, segment: String, diagnosisCode: String, status: PrimaryFloatPoolManifestStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.windowDays = windowDays
            self.score = score
            self.segment = segment
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: PrimaryFloatPoolManifestStatus) -> Bool {
            switch status {
            case .created:
                return next == PrimaryFloatPoolManifestStatus.validated || next == PrimaryFloatPoolManifestStatus.published
            case .validated:
                return next == PrimaryFloatPoolManifestStatus.published
            case .published:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryFloatPoolManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary float pool manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveExposure() -> Double {
            return (cost * score * 100).rounded() / 100
        }

        func copyValue() -> PrimaryFloatPoolManifest {
            return PrimaryFloatPoolManifest(
                code: code,
                label: label,
                cost: cost,
                windowDays: windowDays,
                score: score,
                segment: segment,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a primary float pool manifest in status created.
    static func newPrimaryFloatPoolManifest(_ code: String, label: String) -> PrimaryFloatPoolManifest {
        return PrimaryFloatPoolManifest(
            code: code,
            label: label,
            cost: 0.0,
            windowDays: 0,
            score: 0.0,
            segment: "",
            diagnosisCode: "",
            status: PrimaryFloatPoolManifestStatus.created
        )
    }
}
