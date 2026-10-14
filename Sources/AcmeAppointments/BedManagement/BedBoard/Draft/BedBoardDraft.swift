import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board draft is in its life cycle.
    enum BedBoardDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A bed board draft. Its code is unique within a tenant.
    final class BedBoardDraft {
        var code: String
        var name: String
        var payer: String
        var score: Double
        var region: String
        var phone: String
        var windowDays: Int
        var status: BedBoardDraftStatus

        init(code: String, name: String, payer: String, score: Double, region: String, phone: String, windowDays: Int, status: BedBoardDraftStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.score = score
            self.region = region
            self.phone = phone
            self.windowDays = windowDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BedBoardDraftStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == BedBoardDraftStatus.rejected
            case .rejected:
                return next == BedBoardDraftStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveTotal() -> Double {
            return (score * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardDraft {
            return BedBoardDraft(
                code: code,
                name: name,
                payer: payer,
                score: score,
                region: region,
                phone: phone,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a bed board draft in status proposed.
    static func newBedBoardDraft(_ code: String, name: String) -> BedBoardDraft {
        return BedBoardDraft(
            code: code,
            name: name,
            payer: "",
            score: 0.0,
            region: "",
            phone: "",
            windowDays: 0,
            status: BedBoardDraftStatus.proposed
        )
    }
}
