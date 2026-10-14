import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient remittance manifest is in its life cycle.
    enum LenientRemittanceManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A lenient remittance manifest as the remittance team keeps it.
    final class LenientRemittanceManifest {
        var code: String
        var name: String
        var score: Double
        var rate: Double
        var patientRef: String
        var attributes: [String: String]
        var limit: Int
        var cost: Double
        var revision: Int
        var sequence: Int
        var approved: Bool
        var status: LenientRemittanceManifestStatus

        init(code: String, name: String, score: Double, rate: Double, patientRef: String, attributes: [String: String], limit: Int, cost: Double, revision: Int, sequence: Int, approved: Bool, status: LenientRemittanceManifestStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.rate = rate
            self.patientRef = patientRef
            self.attributes = attributes
            self.limit = limit
            self.cost = cost
            self.revision = revision
            self.sequence = sequence
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

        func canMoveTo(_ next: LenientRemittanceManifestStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientRemittanceManifestStatus.active || next == LenientRemittanceManifestStatus.suspended
            case .pending:
                return next == LenientRemittanceManifestStatus.suspended
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

        func moveTo(_ next: LenientRemittanceManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient remittance manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("lenient remittance manifest") \(code)"
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

        func weightedValue() -> Double {
            return ((Double(revision) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> LenientRemittanceManifest {
            return LenientRemittanceManifest(
                code: code,
                name: name,
                score: score,
                rate: rate,
                patientRef: patientRef,
                attributes: attributes,
                limit: limit,
                cost: cost,
                revision: revision,
                sequence: sequence,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient remittance manifest in status draft.
    static func newLenientRemittanceManifest(_ code: String, name: String) -> LenientRemittanceManifest {
        return LenientRemittanceManifest(
            code: code,
            name: name,
            score: 0.0,
            rate: 0.0,
            patientRef: "",
            attributes: [:],
            limit: 0,
            cost: 0.0,
            revision: 0,
            sequence: 0,
            approved: false,
            status: LenientRemittanceManifestStatus.draft
        )
    }
}
