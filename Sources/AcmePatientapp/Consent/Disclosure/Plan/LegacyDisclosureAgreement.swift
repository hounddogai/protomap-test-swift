import AcmePlatform
import Foundation

extension Consent {
    /// Where a legacy disclosure agreement is in its life cycle.
    enum LegacyDisclosureAgreementStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A legacy disclosure agreement. Its code is unique within a tenant.
    final class LegacyDisclosureAgreement {
        var code: String
        var title: String
        var sequence: Int
        var batchSize: Int
        var createdAt: Int
        var ceiling: Double
        var procedureCode: String
        var segment: String
        var expiresAt: Int
        var description: String
        var attributes: [String: String]
        var status: LegacyDisclosureAgreementStatus

        init(code: String, title: String, sequence: Int, batchSize: Int, createdAt: Int, ceiling: Double, procedureCode: String, segment: String, expiresAt: Int, description: String, attributes: [String: String], status: LegacyDisclosureAgreementStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.batchSize = batchSize
            self.createdAt = createdAt
            self.ceiling = ceiling
            self.procedureCode = procedureCode
            self.segment = segment
            self.expiresAt = expiresAt
            self.description = description
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

        func canMoveTo(_ next: LegacyDisclosureAgreementStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == LegacyDisclosureAgreementStatus.running || next == LegacyDisclosureAgreementStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: LegacyDisclosureAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy disclosure agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
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
            return ((Double(batchSize) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyDisclosureAgreement {
            return LegacyDisclosureAgreement(
                code: code,
                title: title,
                sequence: sequence,
                batchSize: batchSize,
                createdAt: createdAt,
                ceiling: ceiling,
                procedureCode: procedureCode,
                segment: segment,
                expiresAt: expiresAt,
                description: description,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a legacy disclosure agreement in status new.
    static func newLegacyDisclosureAgreement(_ code: String, title: String) -> LegacyDisclosureAgreement {
        return LegacyDisclosureAgreement(
            code: code,
            title: title,
            sequence: 0,
            batchSize: 0,
            createdAt: 0,
            ceiling: 0.0,
            procedureCode: "",
            segment: "",
            expiresAt: 0,
            description: "",
            attributes: [:],
            status: LegacyDisclosureAgreementStatus.new
        )
    }
}
