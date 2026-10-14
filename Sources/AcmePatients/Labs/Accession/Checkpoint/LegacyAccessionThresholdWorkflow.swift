import AcmePlatform
import Foundation

extension Labs {
    /// Moves legacy accession thresholds through their life cycle and keeps a journal of what it did.
    final class LegacyAccessionThresholdDesk {
        var store: any LegacyAccessionThresholdStore
        var validator: LegacyAccessionThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyAccessionThresholdEngine

        init(store: any LegacyAccessionThresholdStore, validator: LegacyAccessionThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyAccessionThresholdEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy accession threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyAccessionThresholdStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy accession threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyAccessionThresholdStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy accession threshold \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newLegacyAccessionThresholdDesk(_ store: any LegacyAccessionThresholdStore, clock: any Kit.Clocks.Clock) -> LegacyAccessionThresholdDesk {
        return LegacyAccessionThresholdDesk(
            store: store,
            validator: defaultLegacyAccessionThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyAccessionThresholdEngine()
        )
    }
}
