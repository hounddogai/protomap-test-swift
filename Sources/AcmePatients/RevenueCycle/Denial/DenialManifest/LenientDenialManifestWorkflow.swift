import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves lenient denial manifests through their life cycle and keeps a journal of what it did.
    final class LenientDenialManifestDesk {
        var store: any LenientDenialManifestStore
        var validator: LenientDenialManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientDenialManifestEngine

        init(store: any LenientDenialManifestStore, validator: LenientDenialManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientDenialManifestEngine) {
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
                throw Kit.Failure("lenient denial manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientDenialManifestStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient denial manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientDenialManifestStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient denial manifest \(code) not found")
            }
            let result = engine.price(item)
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

    static func newLenientDenialManifestDesk(_ store: any LenientDenialManifestStore, clock: any Kit.Clocks.Clock) -> LenientDenialManifestDesk {
        return LenientDenialManifestDesk(
            store: store,
            validator: defaultLenientDenialManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientDenialManifestEngine()
        )
    }
}
