import AcmePlatform
import Foundation

extension Referrals {
    /// Moves capped slot bundles through their life cycle and keeps a journal of what it did.
    final class CappedSlotBundleManager {
        var store: any CappedSlotBundleStore
        var validator: CappedSlotBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedSlotBundleEngine

        init(store: any CappedSlotBundleStore, validator: CappedSlotBundleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedSlotBundleEngine) {
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
                throw Kit.Failure("capped slot bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedSlotBundleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped slot bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedSlotBundleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped slot bundle \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
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

    static func newCappedSlotBundleManager(_ store: any CappedSlotBundleStore, clock: any Kit.Clocks.Clock) -> CappedSlotBundleManager {
        return CappedSlotBundleManager(
            store: store,
            validator: defaultCappedSlotBundleValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedSlotBundleEngine()
        )
    }
}
