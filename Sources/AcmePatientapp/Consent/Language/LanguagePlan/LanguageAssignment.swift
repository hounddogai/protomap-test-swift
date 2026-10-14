import AcmePlatform
import Foundation

extension Consent {
    /// Where a language assignment is in its life cycle.
    enum LanguageAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A language assignment as the language team keeps it.
    final class LanguageAssignment {
        var code: String
        var name: String
        var checksum: String
        var limit: Int
        var diagnosisCode: String
        var cost: Double
        var amount: Double
        var procedureCode: String
        var currency: String
        var attributes: [String: String]
        var status: LanguageAssignmentStatus

        init(code: String, name: String, checksum: String, limit: Int, diagnosisCode: String, cost: Double, amount: Double, procedureCode: String, currency: String, attributes: [String: String], status: LanguageAssignmentStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.limit = limit
            self.diagnosisCode = diagnosisCode
            self.cost = cost
            self.amount = amount
            self.procedureCode = procedureCode
            self.currency = currency
            self.attributes = attributes
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

        func canMoveTo(_ next: LanguageAssignmentStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == LanguageAssignmentStatus.running
            case .running:
                return next == LanguageAssignmentStatus.failed
            case .done:
                return next == LanguageAssignmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("language assignment") \(code)"
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

        func projectedValue() -> Double {
            return ((cost - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> LanguageAssignment {
            return LanguageAssignment(
                code: code,
                name: name,
                checksum: checksum,
                limit: limit,
                diagnosisCode: diagnosisCode,
                cost: cost,
                amount: amount,
                procedureCode: procedureCode,
                currency: currency,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a language assignment in status new.
    static func newLanguageAssignment(_ code: String, name: String) -> LanguageAssignment {
        return LanguageAssignment(
            code: code,
            name: name,
            checksum: "",
            limit: 0,
            diagnosisCode: "",
            cost: 0.0,
            amount: 0.0,
            procedureCode: "",
            currency: "",
            attributes: [:],
            status: LanguageAssignmentStatus.new
        )
    }
}
