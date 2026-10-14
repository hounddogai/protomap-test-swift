import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier tier is in its life cycle.
    enum CourierTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A courier tier as the courier team keeps it.
    final class CourierTier {
        var code: String
        var name: String
        var summary: String
        var attributes: [String: String]
        var allergy: String
        var source: String
        var visible: Bool
        var batchSize: Int
        var clinicianID: String
        var payer: String
        var version: Int
        var status: CourierTierStatus

        init(code: String, name: String, summary: String, attributes: [String: String], allergy: String, source: String, visible: Bool, batchSize: Int, clinicianID: String, payer: String, version: Int, status: CourierTierStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.attributes = attributes
            self.allergy = allergy
            self.source = source
            self.visible = visible
            self.batchSize = batchSize
            self.clinicianID = clinicianID
            self.payer = payer
            self.version = version
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

        func canMoveTo(_ next: CourierTierStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CourierTierStatus.done || next == CourierTierStatus.failed
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

        func moveTo(_ next: CourierTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
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

        func netExposure() -> Double {
            return ((Double(batchSize) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> CourierTier {
            return CourierTier(
                code: code,
                name: name,
                summary: summary,
                attributes: attributes,
                allergy: allergy,
                source: source,
                visible: visible,
                batchSize: batchSize,
                clinicianID: clinicianID,
                payer: payer,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a courier tier in status new.
    static func newCourierTier(_ code: String, name: String) -> CourierTier {
        return CourierTier(
            code: code,
            name: name,
            summary: "",
            attributes: [:],
            allergy: "",
            source: "",
            visible: false,
            batchSize: 0,
            clinicianID: "",
            payer: "",
            version: 0,
            status: CourierTierStatus.new
        )
    }
}
