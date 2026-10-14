import AcmePlatform
import Foundation

extension Imaging {
    /// Moves lenient care protocol bundles through their life cycle and keeps a journal of what it did.
    final class LenientCareProtocolBundleCoordinator {
        var store: any LenientCareProtocolBundleStore
        var validator: LenientCareProtocolBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LenientCareProtocolBundleStore, validator: LenientCareProtocolBundleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient care protocol bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientCareProtocolBundleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient care protocol bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientCareProtocolBundleStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newLenientCareProtocolBundleCoordinator(_ store: any LenientCareProtocolBundleStore, clock: any Kit.Clocks.Clock) -> LenientCareProtocolBundleCoordinator {
        return LenientCareProtocolBundleCoordinator(
            store: store,
            validator: defaultLenientCareProtocolBundleValidator(),
            clock: clock,
            journal: []
        )
    }
}
