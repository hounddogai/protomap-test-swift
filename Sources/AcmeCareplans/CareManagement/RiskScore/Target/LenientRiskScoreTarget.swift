import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient risk score target is in its life cycle.
    enum LenientRiskScoreTargetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a lenient risk score target and its current status.
    final class LenientRiskScoreTarget {
        var code: String
        var label: String
        var revision: Int
        var segment: String
        var locale: String
        var batchSize: Int
        var status: LenientRiskScoreTargetStatus

        init(code: String, label: String, revision: Int, segment: String, locale: String, batchSize: Int, status: LenientRiskScoreTargetStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.segment = segment
            self.locale = locale
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientRiskScoreTargetStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientRiskScoreTargetStatus.revoked || next == LenientRiskScoreTargetStatus.expired
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == LenientRiskScoreTargetStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientRiskScoreTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient risk score target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedExposure() -> Double {
            return (Double(batchSize) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> LenientRiskScoreTarget {
            return LenientRiskScoreTarget(
                code: code,
                label: label,
                revision: revision,
                segment: segment,
                locale: locale,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a lenient risk score target in status requested.
    static func newLenientRiskScoreTarget(_ code: String, label: String) -> LenientRiskScoreTarget {
        return LenientRiskScoreTarget(
            code: code,
            label: label,
            revision: 0,
            segment: "",
            locale: "",
            batchSize: 0,
            status: LenientRiskScoreTargetStatus.requested
        )
    }
}
