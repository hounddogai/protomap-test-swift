import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive care gap notice is in its life cycle.
    enum AdaptiveCareGapNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One adaptive care gap notice, with what the planners need to act on it.
    final class AdaptiveCareGapNotice {
        var code: String
        var name: String
        var score: Double
        var source: String
        var specialty: String
        var approved: Bool
        var payer: String
        var patientRef: String
        var ratio: Double
        var externalRef: String
        var status: AdaptiveCareGapNoticeStatus

        init(code: String, name: String, score: Double, source: String, specialty: String, approved: Bool, payer: String, patientRef: String, ratio: Double, externalRef: String, status: AdaptiveCareGapNoticeStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.source = source
            self.specialty = specialty
            self.approved = approved
            self.payer = payer
            self.patientRef = patientRef
            self.ratio = ratio
            self.externalRef = externalRef
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

        func canMoveTo(_ next: AdaptiveCareGapNoticeStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == AdaptiveCareGapNoticeStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveCareGapNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive care gap notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive care gap notice") \(code)"
        }

        func projectedValue() -> Double {
            return ((score - ratio) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveCareGapNotice {
            return AdaptiveCareGapNotice(
                code: code,
                name: name,
                score: score,
                source: source,
                specialty: specialty,
                approved: approved,
                payer: payer,
                patientRef: patientRef,
                ratio: ratio,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a adaptive care gap notice in status requested.
    static func newAdaptiveCareGapNotice(_ code: String, name: String) -> AdaptiveCareGapNotice {
        return AdaptiveCareGapNotice(
            code: code,
            name: name,
            score: 0.0,
            source: "",
            specialty: "",
            approved: false,
            payer: "",
            patientRef: "",
            ratio: 0.0,
            externalRef: "",
            status: AdaptiveCareGapNoticeStatus.requested
        )
    }
}
