import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves lenient remittance bundles through their life cycle and keeps a journal of what it did.
    final class LenientRemittanceBundleManager {
        var store: any LenientRemittanceBundleStore
        var validator: LenientRemittanceBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientRemittanceBundleEngine

        init(store: any LenientRemittanceBundleStore, validator: LenientRemittanceBundleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientRemittanceBundleEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient remittance bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientRemittanceBundleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient remittance bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientRemittanceBundleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient remittance bundle \(code) not found")
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

    static func newLenientRemittanceBundleManager(_ store: any LenientRemittanceBundleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientRemittanceBundleManager {
        return LenientRemittanceBundleManager(
            store: store,
            validator: defaultLenientRemittanceBundleValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientRemittanceBundleEngine(flags)
        )
    }
}
