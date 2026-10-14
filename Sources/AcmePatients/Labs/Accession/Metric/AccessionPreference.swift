import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession preference is in its life cycle.
    enum AccessionPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One accession preference, with what the planners need to act on it.
    final class AccessionPreference {
        var code: String
        var title: String
        var patientRef: String
        var acuity: Int
        var priority: Int
        var createdAt: Int
        var dosageMg: Double
        var source: String
        var approved: Bool
        var ownerID: String
        var status: AccessionPreferenceStatus

        init(code: String, title: String, patientRef: String, acuity: Int, priority: Int, createdAt: Int, dosageMg: Double, source: String, approved: Bool, ownerID: String, status: AccessionPreferenceStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.acuity = acuity
            self.priority = priority
            self.createdAt = createdAt
            self.dosageMg = dosageMg
            self.source = source
            self.approved = approved
            self.ownerID = ownerID
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

        func canMoveTo(_ next: AccessionPreferenceStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == AccessionPreferenceStatus.suspended || next == AccessionPreferenceStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: AccessionPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("accession preference") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(acuity) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> AccessionPreference {
            return AccessionPreference(
                code: code,
                title: title,
                patientRef: patientRef,
                acuity: acuity,
                priority: priority,
                createdAt: createdAt,
                dosageMg: dosageMg,
                source: source,
                approved: approved,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a accession preference in status draft.
    static func newAccessionPreference(_ code: String, title: String) -> AccessionPreference {
        return AccessionPreference(
            code: code,
            title: title,
            patientRef: "",
            acuity: 0,
            priority: 0,
            createdAt: 0,
            dosageMg: 0.0,
            source: "",
            approved: false,
            ownerID: "",
            status: AccessionPreferenceStatus.draft
        )
    }
}
