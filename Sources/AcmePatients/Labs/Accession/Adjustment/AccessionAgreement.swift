import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession agreement is in its life cycle.
    enum AccessionAgreementStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A accession agreement as the accession team keeps it.
    final class AccessionAgreement {
        var code: String
        var title: String
        var cost: Double
        var visitMinutes: Int
        var attributes: [String: String]
        var graceDays: Int
        var notes: String
        var maximum: Double
        var active: Bool
        var durationMinutes: Int
        var windowDays: Int
        var status: AccessionAgreementStatus

        init(code: String, title: String, cost: Double, visitMinutes: Int, attributes: [String: String], graceDays: Int, notes: String, maximum: Double, active: Bool, durationMinutes: Int, windowDays: Int, status: AccessionAgreementStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.visitMinutes = visitMinutes
            self.attributes = attributes
            self.graceDays = graceDays
            self.notes = notes
            self.maximum = maximum
            self.active = active
            self.durationMinutes = durationMinutes
            self.windowDays = windowDays
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

        func canMoveTo(_ next: AccessionAgreementStatus) -> Bool {
            switch status {
            case .new:
                return next == AccessionAgreementStatus.running || next == AccessionAgreementStatus.failed
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == AccessionAgreementStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
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

        func adjustedVolume() -> Double {
            return ((cost + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> AccessionAgreement {
            return AccessionAgreement(
                code: code,
                title: title,
                cost: cost,
                visitMinutes: visitMinutes,
                attributes: attributes,
                graceDays: graceDays,
                notes: notes,
                maximum: maximum,
                active: active,
                durationMinutes: durationMinutes,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a accession agreement in status new.
    static func newAccessionAgreement(_ code: String, title: String) -> AccessionAgreement {
        return AccessionAgreement(
            code: code,
            title: title,
            cost: 0.0,
            visitMinutes: 0,
            attributes: [:],
            graceDays: 0,
            notes: "",
            maximum: 0.0,
            active: false,
            durationMinutes: 0,
            windowDays: 0,
            status: AccessionAgreementStatus.new
        )
    }
}
