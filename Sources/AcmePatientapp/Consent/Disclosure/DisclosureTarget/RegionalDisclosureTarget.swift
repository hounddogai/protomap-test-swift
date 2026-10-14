import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional disclosure target is in its life cycle.
    enum RegionalDisclosureTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a regional disclosure target and its current status.
    final class RegionalDisclosureTarget {
        var code: String
        var name: String
        var startsAt: Int
        var source: String
        var windowDays: Int
        var description: String
        var procedureCode: String
        var ward: String
        var clinicianID: String
        var status: RegionalDisclosureTargetStatus

        init(code: String, name: String, startsAt: Int, source: String, windowDays: Int, description: String, procedureCode: String, ward: String, clinicianID: String, status: RegionalDisclosureTargetStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.source = source
            self.windowDays = windowDays
            self.description = description
            self.procedureCode = procedureCode
            self.ward = ward
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: RegionalDisclosureTargetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == RegionalDisclosureTargetStatus.suspended
            case .active:
                return next == RegionalDisclosureTargetStatus.suspended || next == RegionalDisclosureTargetStatus.closed
            case .suspended:
                return next == RegionalDisclosureTargetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalDisclosureTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional disclosure target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedExposure() -> Double {
            return ((Double(startsAt) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalDisclosureTarget {
            return RegionalDisclosureTarget(
                code: code,
                name: name,
                startsAt: startsAt,
                source: source,
                windowDays: windowDays,
                description: description,
                procedureCode: procedureCode,
                ward: ward,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a regional disclosure target in status draft.
    static func newRegionalDisclosureTarget(_ code: String, name: String) -> RegionalDisclosureTarget {
        return RegionalDisclosureTarget(
            code: code,
            name: name,
            startsAt: 0,
            source: "",
            windowDays: 0,
            description: "",
            procedureCode: "",
            ward: "",
            clinicianID: "",
            status: RegionalDisclosureTargetStatus.draft
        )
    }
}
