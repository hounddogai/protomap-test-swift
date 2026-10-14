import AcmePlatform
import Foundation

extension Labs {
    /// Moves rolling panel mappings through their life cycle and keeps a journal of what it did.
    final class RollingPanelMappingManager {
        var store: any RollingPanelMappingStore
        var validator: RollingPanelMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingPanelMappingEngine

        init(store: any RollingPanelMappingStore, validator: RollingPanelMappingValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingPanelMappingEngine) {
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
                throw Kit.Failure("rolling panel mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingPanelMappingStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling panel mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingPanelMappingStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling panel mapping \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newRollingPanelMappingManager(_ store: any RollingPanelMappingStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingPanelMappingManager {
        return RollingPanelMappingManager(
            store: store,
            validator: defaultRollingPanelMappingValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingPanelMappingEngine(flags)
        )
    }
}
