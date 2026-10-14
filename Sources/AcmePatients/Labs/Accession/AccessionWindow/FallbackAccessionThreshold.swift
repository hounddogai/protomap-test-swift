import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback accession threshold is in its life cycle.
    enum FallbackAccessionThresholdStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a fallback accession threshold and its current status.
    final class FallbackAccessionThreshold {
        var code: String
        var name: String
        var endsAt: Int
        var label: String
        var margin: Double
        var externalRef: String
        var attributes: [String: String]
        var approved: Bool
        var batchSize: Int
        var segment: String
        var status: FallbackAccessionThresholdStatus

        init(code: String, name: String, endsAt: Int, label: String, margin: Double, externalRef: String, attributes: [String: String], approved: Bool, batchSize: Int, segment: String, status: FallbackAccessionThresholdStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.label = label
            self.margin = margin
            self.externalRef = externalRef
            self.attributes = attributes
            self.approved = approved
            self.batchSize = batchSize
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackAccessionThresholdStatus) -> Bool {
            switch status {
            case .created:
                return next == FallbackAccessionThresholdStatus.retired
            case .validated:
                return next == FallbackAccessionThresholdStatus.retired
            case .published:
                return next == FallbackAccessionThresholdStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackAccessionThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback accession threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
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

        func projectedTotal() -> Double {
            return (margin * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> FallbackAccessionThreshold {
            return FallbackAccessionThreshold(
                code: code,
                name: name,
                endsAt: endsAt,
                label: label,
                margin: margin,
                externalRef: externalRef,
                attributes: attributes,
                approved: approved,
                batchSize: batchSize,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a fallback accession threshold in status created.
    static func newFallbackAccessionThreshold(_ code: String, name: String) -> FallbackAccessionThreshold {
        return FallbackAccessionThreshold(
            code: code,
            name: name,
            endsAt: 0,
            label: "",
            margin: 0.0,
            externalRef: "",
            attributes: [:],
            approved: false,
            batchSize: 0,
            segment: "",
            status: FallbackAccessionThresholdStatus.created
        )
    }
}
