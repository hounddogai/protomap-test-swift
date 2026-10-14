import AcmePlatform
import Foundation

extension Referrals {
    /// Where a lenient eligibility estimate is in its life cycle.
    enum LenientEligibilityEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a lenient eligibility estimate and its current status.
    final class LenientEligibilityEstimate {
        var code: String
        var name: String
        var diagnosisCode: String
        var tags: [String]
        var revision: Int
        var summary: String
        var ward: String
        var floorValue: Double
        var status: LenientEligibilityEstimateStatus

        init(code: String, name: String, diagnosisCode: String, tags: [String], revision: Int, summary: String, ward: String, floorValue: Double, status: LenientEligibilityEstimateStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.tags = tags
            self.revision = revision
            self.summary = summary
            self.ward = ward
            self.floorValue = floorValue
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

        func canMoveTo(_ next: LenientEligibilityEstimateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == LenientEligibilityEstimateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientEligibilityEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient eligibility estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedLoad() -> Double {
            return ((floorValue - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> LenientEligibilityEstimate {
            return LenientEligibilityEstimate(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                tags: tags,
                revision: revision,
                summary: summary,
                ward: ward,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a lenient eligibility estimate in status new.
    static func newLenientEligibilityEstimate(_ code: String, name: String) -> LenientEligibilityEstimate {
        return LenientEligibilityEstimate(
            code: code,
            name: name,
            diagnosisCode: "",
            tags: [],
            revision: 0,
            summary: "",
            ward: "",
            floorValue: 0.0,
            status: LenientEligibilityEstimateStatus.new
        )
    }
}
