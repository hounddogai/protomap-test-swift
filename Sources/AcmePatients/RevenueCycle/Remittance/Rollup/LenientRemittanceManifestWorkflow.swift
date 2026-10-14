import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves lenient remittance manifests through their life cycle and keeps a journal of what it did.
    final class LenientRemittanceManifestManager {
        var store: any LenientRemittanceManifestStore
        var validator: LenientRemittanceManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientRemittanceManifestEngine

        init(store: any LenientRemittanceManifestStore, validator: LenientRemittanceManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientRemittanceManifestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient remittance manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientRemittanceManifestStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient remittance manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientRemittanceManifestStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient remittance manifest \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newLenientRemittanceManifestManager(_ store: any LenientRemittanceManifestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientRemittanceManifestManager {
        return LenientRemittanceManifestManager(
            store: store,
            validator: defaultLenientRemittanceManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientRemittanceManifestEngine(flags)
        )
    }
}
