import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure preference is in its life cycle.
    enum ClosurePreferenceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One closure preference, with what the planners need to act on it.
    final class ClosurePreference {
        var code: String
        var title: String
        var capacity: Int
        var payer: String
        var region: String
        var ward: String
        var version: Int
        var score: Double
        var budget: Double
        var diagnosisCode: String
        var patientRef: String
        var status: ClosurePreferenceStatus

        init(code: String, title: String, capacity: Int, payer: String, region: String, ward: String, version: Int, score: Double, budget: Double, diagnosisCode: String, patientRef: String, status: ClosurePreferenceStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.payer = payer
            self.region = region
            self.ward = ward
            self.version = version
            self.score = score
            self.budget = budget
            self.diagnosisCode = diagnosisCode
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClosurePreferenceStatus) -> Bool {
            switch status {
            case .new:
                return next == ClosurePreferenceStatus.queued
            case .queued:
                return next == ClosurePreferenceStatus.failed
            case .running:
                return next == ClosurePreferenceStatus.done || next == ClosurePreferenceStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ClosurePreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveValue() -> Double {
            return ((Double(version) + score) * 100).rounded() / 100
        }

        func copyValue() -> ClosurePreference {
            return ClosurePreference(
                code: code,
                title: title,
                capacity: capacity,
                payer: payer,
                region: region,
                ward: ward,
                version: version,
                score: score,
                budget: budget,
                diagnosisCode: diagnosisCode,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a closure preference in status new.
    static func newClosurePreference(_ code: String, title: String) -> ClosurePreference {
        return ClosurePreference(
            code: code,
            title: title,
            capacity: 0,
            payer: "",
            region: "",
            ward: "",
            version: 0,
            score: 0.0,
            budget: 0.0,
            diagnosisCode: "",
            patientRef: "",
            status: ClosurePreferenceStatus.new
        )
    }
}
