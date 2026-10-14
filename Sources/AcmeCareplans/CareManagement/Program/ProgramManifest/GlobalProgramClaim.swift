import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global program claim is in its life cycle.
    enum GlobalProgramClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a global program claim and its current status.
    final class GlobalProgramClaim {
        var code: String
        var title: String
        var windowDays: Int
        var approved: Bool
        var startsAt: Int
        var archived: Bool
        var dosageMg: Double
        var locale: String
        var status: GlobalProgramClaimStatus

        init(code: String, title: String, windowDays: Int, approved: Bool, startsAt: Int, archived: Bool, dosageMg: Double, locale: String, status: GlobalProgramClaimStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.approved = approved
            self.startsAt = startsAt
            self.archived = archived
            self.dosageMg = dosageMg
            self.locale = locale
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

        func canMoveTo(_ next: GlobalProgramClaimStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == GlobalProgramClaimStatus.done || next == GlobalProgramClaimStatus.failed
            case .done:
                return next == GlobalProgramClaimStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalProgramClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global program claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("global program claim") \(code)"
        }

        func effectiveExposure() -> Double {
            return (dosageMg * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> GlobalProgramClaim {
            return GlobalProgramClaim(
                code: code,
                title: title,
                windowDays: windowDays,
                approved: approved,
                startsAt: startsAt,
                archived: archived,
                dosageMg: dosageMg,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a global program claim in status new.
    static func newGlobalProgramClaim(_ code: String, title: String) -> GlobalProgramClaim {
        return GlobalProgramClaim(
            code: code,
            title: title,
            windowDays: 0,
            approved: false,
            startsAt: 0,
            archived: false,
            dosageMg: 0.0,
            locale: "",
            status: GlobalProgramClaimStatus.new
        )
    }
}
