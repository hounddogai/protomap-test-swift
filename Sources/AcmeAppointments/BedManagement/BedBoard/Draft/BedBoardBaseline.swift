import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board baseline is in its life cycle.
    enum BedBoardBaselineStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A bed board baseline. Its code is unique within a tenant.
    final class BedBoardBaseline {
        var code: String
        var label: String
        var visitMinutes: Int
        var locale: String
        var score: Double
        var phone: String
        var notes: String
        var refills: Int
        var externalRef: String
        var minimum: Double
        var approved: Bool
        var status: BedBoardBaselineStatus

        init(code: String, label: String, visitMinutes: Int, locale: String, score: Double, phone: String, notes: String, refills: Int, externalRef: String, minimum: Double, approved: Bool, status: BedBoardBaselineStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.locale = locale
            self.score = score
            self.phone = phone
            self.notes = notes
            self.refills = refills
            self.externalRef = externalRef
            self.minimum = minimum
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BedBoardBaselineStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: BedBoardBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedValue() -> Double {
            return (Double(refills) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardBaseline {
            return BedBoardBaseline(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                locale: locale,
                score: score,
                phone: phone,
                notes: notes,
                refills: refills,
                externalRef: externalRef,
                minimum: minimum,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a bed board baseline in status draft.
    static func newBedBoardBaseline(_ code: String, label: String) -> BedBoardBaseline {
        return BedBoardBaseline(
            code: code,
            label: label,
            visitMinutes: 0,
            locale: "",
            score: 0.0,
            phone: "",
            notes: "",
            refills: 0,
            externalRef: "",
            minimum: 0.0,
            approved: false,
            status: BedBoardBaselineStatus.draft
        )
    }
}
